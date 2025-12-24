# How to Connect a USB Webcam to WSL 2

Running a native Linux app with camera access in WSL 2 requires attaching the physical USB device from Windows to Linux. This allows the Linux kernel to see the device at `/dev/video0`.

> [!WARNING]
> This requires installing software on your **Windows** host machine and running commands in a Windows Administrator terminal.

## Prerequisites
- **Windows 11** (Build 22000 or later).
- **WSL 2** kernel version 5.10.60.1 or later.

## Step 1: Install `usbipd-win` on Windows
1. On **Windows**, open a terminal (PowerShell or Command Prompt).
2. Install the USB IPD tool using `winget`:
   ```powershell
   winget install usbipd
   ```
3. Restart your terminal after installation.

## Step 2: Attach the Camera
1. List all USB devices connected to Windows:
   ```powershell
   usbipd list
   ```
2. Find your webcam in the list and note its **BUSID** (e.g., `1-2`).
3. Bind the device (run as Administrator if needed):
   ```powershell
   usbipd bind --busid <BUSID>
   ```
4. Attach the device to WSL:
   ```powershell
   usbipd attach --wsl --busid <BUSID>
   ```

## Step 3: Verify in WSL Linux
1. Go back to your **Linux** terminal (where you are running the app).
2. Check if the device exists:
   ```bash
   ls -l /dev/video*
   ```
   If successful, you should see `/dev/video0` and/or `/dev/video1`.

## Step 4: Run the App
Now you can run the native Linux app, and it should detect the camera:
```bash
npm run start:linux
```

---

## Alternative: Use Web Browser (Easier)
If the above is too complicated, you can just run the Web version. It uses your Windows browser to access the camera without any complex setup.

1. **In Linux Terminal**:
   ```bash
   npm run start:web-server
   ```
2. **In Windows Chrome**:
   - Open the link shown (likely `http://localhost:8080`).
   - Click "Allow" when asked for camera permission.
