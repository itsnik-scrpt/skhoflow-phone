using SkhoFlow.Host.Models;
using System;

namespace SkhoFlow.Host.Services;

/// <summary>Composition root — single place to grab shared services from anywhere in the app.</summary>
public sealed class AppHost
{
    public SettingsStore Settings { get; } = new();
    public DiscoveryService Discovery { get; } = new();
    public PairingService Pairing { get; private set; } = null!;
    public IStreamingHost Streaming { get; } = new StreamingHost();

    public event EventHandler<string>? HostStatusChanged;

    private bool _initialized;

    public void Initialize()
    {
        if (_initialized) return;
        _initialized = true;

        Settings.Load();
        Pairing = new PairingService(Settings);

        Pairing.Start(Settings.Settings.Stream.ControlPort);
        Discovery.Start(Settings.Settings.HostName, Settings.Settings.Stream.ControlPort, Pairing.HostId);

        Streaming.StateChanged += (_, state) =>
            HostStatusChanged?.Invoke(this, state == "streaming" ? "Streaming" : "Ready");

        HostStatusChanged?.Invoke(this, "Ready");
    }

    public void Shutdown()
    {
        try { Streaming.StopAsync().Wait(500); } catch { }
        Pairing?.Stop();
        Discovery.Stop();
    }
}
