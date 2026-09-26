param([int]$ParentProcess)

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class Desktop {
	[StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
	[StructLayout(LayoutKind.Sequential)] public struct MonitorInfo { public int Size; public Rect Monitor; public Rect Work; public uint Flags; }
	[StructLayout(LayoutKind.Sequential)] public struct LastInputInfo { public uint Size; public uint Time; }

	[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
	[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr window, out Rect rect);
	[DllImport("user32.dll")] public static extern IntPtr MonitorFromWindow(IntPtr window, uint flags);
	[DllImport("user32.dll")] public static extern bool GetMonitorInfo(IntPtr monitor, ref MonitorInfo info);
	[DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref LastInputInfo info);
	[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);
	[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr window, StringBuilder name, int length);
	[DllImport("user32.dll")] public static extern IntPtr GetWindowLongPtr(IntPtr window, int index);
	[DllImport("user32.dll")] public static extern IntPtr SetWindowLongPtr(IntPtr window, int index, IntPtr value);
	[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr window, int command);
	[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr window);
	[DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr window);
	public delegate bool WindowCallback(IntPtr window, IntPtr data);
	[DllImport("user32.dll")] public static extern bool EnumWindows(WindowCallback callback, IntPtr data);

	public static void HideFromTaskbar(uint processId) {
		EnumWindows((window, data) => {
			uint owner;
			GetWindowThreadProcessId(window, out owner);
			long style = GetWindowLongPtr(window, -20).ToInt64();
			if (owner == processId && IsWindowVisible(window) && (style & 0x80) == 0) {
				ShowWindow(window, 0);
				SetWindowLongPtr(window, -20, new IntPtr((style | 0x80) & ~0x40000));
				ShowWindow(window, 4);
			}
			return true;
		}, IntPtr.Zero);
	}

	public static uint IdleSeconds() {
		var info = new LastInputInfo();
		info.Size = (uint)Marshal.SizeOf(info);
		GetLastInputInfo(ref info);
		return ((uint)Environment.TickCount - info.Time) / 1000;
	}

	public static bool IsFullscreen(IntPtr window) {
		if (window == IntPtr.Zero || IsZoomed(window)) return false;
		var className = new StringBuilder(64);
		GetClassName(window, className, 64);
		var desktopClasses = new[] { "Progman", "WorkerW", "Shell_TrayWnd" };
		if (Array.IndexOf(desktopClasses, className.ToString()) >= 0) return false;
		Rect rect;
		GetWindowRect(window, out rect);
		var info = new MonitorInfo();
		info.Size = Marshal.SizeOf(info);
		GetMonitorInfo(MonitorFromWindow(window, 2), ref info);
		return rect.Left <= info.Monitor.Left && rect.Top <= info.Monitor.Top && rect.Right >= info.Monitor.Right && rect.Bottom >= info.Monitor.Bottom;
	}
}
"@

while (Get-Process -Id $ParentProcess -ErrorAction SilentlyContinue) {
	[Desktop]::HideFromTaskbar([uint32]$ParentProcess)
	$foreground = [Desktop]::GetForegroundWindow()
	$foregroundProcess = 0
	[void][Desktop]::GetWindowThreadProcessId($foreground, [ref]$foregroundProcess)
	$appName = ""
	$fullscreen = 0
	if ($foregroundProcess -ne 0 -and $foregroundProcess -ne $ParentProcess) {
		$appName = (Get-Process -Id $foregroundProcess -ErrorAction SilentlyContinue).ProcessName
		if ([Desktop]::IsFullscreen($foreground)) { $fullscreen = 1 }
	}
	[Console]::Out.WriteLine("$([Desktop]::IdleSeconds())|$fullscreen|$appName")
	[Console]::Out.Flush()
	Start-Sleep -Seconds 1
}
