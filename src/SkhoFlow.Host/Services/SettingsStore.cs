using SkhoFlow.Host.Models;
using System;
using System.IO;
using System.Text.Json;

namespace SkhoFlow.Host.Services;

public sealed class SettingsStore
{
    private static readonly string SettingsDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "SkhoFlow");

    private static readonly string SettingsPath = Path.Combine(SettingsDir, "settings.json");
    private static readonly string DevicesPath = Path.Combine(SettingsDir, "devices.json");

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        WriteIndented = true,
        PropertyNameCaseInsensitive = true,
    };

    public AppSettings Settings { get; private set; } = new();
    public List<PairedDevice> Devices { get; private set; } = new();

    public event EventHandler? SettingsChanged;
    public event EventHandler? DevicesChanged;

    public void Load()
    {
        Directory.CreateDirectory(SettingsDir);

        if (File.Exists(SettingsPath))
        {
            try
            {
                var json = File.ReadAllText(SettingsPath);
                Settings = JsonSerializer.Deserialize<AppSettings>(json, JsonOpts) ?? new();
            }
            catch { Settings = new(); }
        }

        if (File.Exists(DevicesPath))
        {
            try
            {
                var json = File.ReadAllText(DevicesPath);
                Devices = JsonSerializer.Deserialize<List<PairedDevice>>(json, JsonOpts) ?? new();
            }
            catch { Devices = new(); }
        }
    }

    public void SaveSettings()
    {
        Directory.CreateDirectory(SettingsDir);
        File.WriteAllText(SettingsPath, JsonSerializer.Serialize(Settings, JsonOpts));
        SettingsChanged?.Invoke(this, EventArgs.Empty);
    }

    public void SaveDevices()
    {
        Directory.CreateDirectory(SettingsDir);
        File.WriteAllText(DevicesPath, JsonSerializer.Serialize(Devices, JsonOpts));
        DevicesChanged?.Invoke(this, EventArgs.Empty);
    }

    public void AddOrUpdateDevice(PairedDevice device)
    {
        var idx = Devices.FindIndex(d => d.Id == device.Id);
        if (idx >= 0) Devices[idx] = device;
        else Devices.Add(device);
        SaveDevices();
    }

    public void RemoveDevice(string id)
    {
        Devices.RemoveAll(d => d.Id == id);
        SaveDevices();
    }
}
