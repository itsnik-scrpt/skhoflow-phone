using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using SkhoFlow.Host.Models;
using System;

namespace SkhoFlow.Host.Pages;

public sealed partial class SessionPage : Page
{
    private int _droppedTotal;

    public SessionPage()
    {
        InitializeComponent();
        Loaded += OnLoaded;
        Unloaded += OnUnloaded;
        App.Host.Streaming.StatsUpdated += OnStatsUpdated;
        App.Host.Streaming.StateChanged += OnStateChanged;
    }

    private void OnLoaded(object sender, RoutedEventArgs e) => RefreshVisibility();
    private void OnUnloaded(object sender, RoutedEventArgs e)
    {
        App.Host.Streaming.StatsUpdated -= OnStatsUpdated;
        App.Host.Streaming.StateChanged -= OnStateChanged;
    }

    private void OnStateChanged(object? sender, string state)
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            if (state == "idle") _droppedTotal = 0;
            RefreshVisibility();
        });
    }

    private void RefreshVisibility()
    {
        var active = App.Host.Streaming.IsActive;
        IdleCard.Visibility = active ? Visibility.Collapsed : Visibility.Visible;
        LiveCard.Visibility = active ? Visibility.Visible : Visibility.Collapsed;
        StatsGrid.Visibility = active ? Visibility.Visible : Visibility.Collapsed;
        SessionSubtitle.Text = active
            ? "A device is streaming. Live telemetry below."
            : "Nothing streaming. Start a session from Home.";
    }

    private void OnStatsUpdated(object? sender, SessionStats stats)
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            LiveDeviceName.Text = stats.DeviceName;
            LiveUptime.Text = $"{stats.Resolution}  ·  {stats.Encoder}  ·  uptime {FormatUptime(stats.UptimeSeconds)}";
            StatFps.Text = stats.Fps.ToString();
            StatLatency.Text = stats.LatencyMs.ToString();
            StatBitrate.Text = (stats.BitrateKbps / 1000.0).ToString("0.0");
            _droppedTotal += stats.DroppedFrames;
            StatDropped.Text = _droppedTotal.ToString();
        });
    }

    private static string FormatUptime(double seconds)
    {
        var ts = TimeSpan.FromSeconds(seconds);
        return ts.TotalHours >= 1
            ? $"{(int)ts.TotalHours}h {ts.Minutes:D2}m"
            : $"{ts.Minutes:D2}:{ts.Seconds:D2}";
    }

    private async void StopSession_Click(object sender, RoutedEventArgs e)
    {
        await App.Host.Streaming.StopAsync();
    }
}
