using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using SkhoFlow.Host.Models;
using System;

namespace SkhoFlow.Host.Pages;

public sealed partial class SettingsPage : Page
{
    private bool _suppress;

    public SettingsPage()
    {
        InitializeComponent();
        Loaded += OnLoaded;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        _suppress = true;
        var s = App.Host.Settings.Settings;

        // Resolution
        foreach (ComboBoxItem item in ResolutionCombo.Items)
        {
            if (item.Tag is string tag && int.TryParse(tag, out var h) && h == s.Stream.Height)
            { item.IsSelected = true; break; }
        }

        // Fps
        foreach (ComboBoxItem item in FpsCombo.Items)
        {
            if (item.Tag is string tag && int.TryParse(tag, out var f) && f == s.Stream.Fps)
            { item.IsSelected = true; break; }
        }

        // Bitrate
        BitrateSlider.Value = s.Stream.BitrateKbps / 1000.0;
        BitrateValueText.Text = $"{s.Stream.BitrateKbps / 1000} Mbps";

        // Codec
        foreach (ComboBoxItem item in CodecCombo.Items)
        {
            if (item.Tag is string tag && tag.Equals(s.Stream.Codec.ToString(), StringComparison.OrdinalIgnoreCase))
            { item.IsSelected = true; break; }
        }

        // Encoder
        foreach (ComboBoxItem item in EncoderCombo.Items)
        {
            if (item.Tag is string tag && tag.Equals(s.Stream.Encoder.ToString(), StringComparison.OrdinalIgnoreCase))
            { item.IsSelected = true; break; }
        }

        AudioToggle.IsOn = s.Stream.AudioEnabled;
        PinToggle.IsOn = s.RequirePin;
        HostNameTextBox.Text = s.HostName;
        ControlPortBox.Value = s.Stream.ControlPort;
        VideoPortBox.Value = s.Stream.Port;
        AutostartToggle.IsOn = s.StartWithWindows;
        TrayToggle.IsOn = s.MinimizeToTray;

        _suppress = false;
    }

    private void Save() => App.Host.Settings.SaveSettings();

    private void Resolution_Changed(object sender, SelectionChangedEventArgs e)
    {
        if (_suppress) return;
        if (ResolutionCombo.SelectedItem is ComboBoxItem item &&
            item.Tag is string tag && int.TryParse(tag, out var h))
        {
            App.Host.Settings.Settings.Stream.Height = h;
            App.Host.Settings.Settings.Stream.Width = h switch
            {
                720 => 1280, 1080 => 1920, 1440 => 2560, 2160 => 3840, _ => 1920,
            };
            Save();
        }
    }

    private void Fps_Changed(object sender, SelectionChangedEventArgs e)
    {
        if (_suppress) return;
        if (FpsCombo.SelectedItem is ComboBoxItem item &&
            item.Tag is string tag && int.TryParse(tag, out var f))
        {
            App.Host.Settings.Settings.Stream.Fps = f;
            Save();
        }
    }

    private void Bitrate_Changed(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (_suppress) return;
        var mbps = (int)Math.Round(e.NewValue);
        App.Host.Settings.Settings.Stream.BitrateKbps = mbps * 1000;
        if (BitrateValueText != null) BitrateValueText.Text = $"{mbps} Mbps";
        Save();
    }

    private void Codec_Changed(object sender, SelectionChangedEventArgs e)
    {
        if (_suppress) return;
        if (CodecCombo.SelectedItem is ComboBoxItem item && item.Tag is string tag &&
            Enum.TryParse<VideoCodec>(tag, true, out var codec))
        {
            App.Host.Settings.Settings.Stream.Codec = codec;
            Save();
        }
    }

    private void Encoder_Changed(object sender, SelectionChangedEventArgs e)
    {
        if (_suppress) return;
        if (EncoderCombo.SelectedItem is ComboBoxItem item && item.Tag is string tag &&
            Enum.TryParse<EncoderKind>(tag, true, out var enc))
        {
            App.Host.Settings.Settings.Stream.Encoder = enc;
            Save();
        }
    }

    private void Audio_Toggled(object sender, RoutedEventArgs e)
    {
        if (_suppress) return;
        App.Host.Settings.Settings.Stream.AudioEnabled = AudioToggle.IsOn;
        Save();
    }

    private void Pin_Toggled(object sender, RoutedEventArgs e)
    {
        if (_suppress) return;
        App.Host.Settings.Settings.RequirePin = PinToggle.IsOn;
        Save();
    }

    private void HostName_Changed(object sender, TextChangedEventArgs e)
    {
        if (_suppress) return;
        App.Host.Settings.Settings.HostName = HostNameTextBox.Text;
        Save();
    }

    private void ControlPort_Changed(NumberBox sender, NumberBoxValueChangedEventArgs args)
    {
        if (_suppress || double.IsNaN(args.NewValue)) return;
        App.Host.Settings.Settings.Stream.ControlPort = (int)args.NewValue;
        Save();
    }

    private void VideoPort_Changed(NumberBox sender, NumberBoxValueChangedEventArgs args)
    {
        if (_suppress || double.IsNaN(args.NewValue)) return;
        App.Host.Settings.Settings.Stream.Port = (int)args.NewValue;
        Save();
    }

    private void Autostart_Toggled(object sender, RoutedEventArgs e)
    {
        if (_suppress) return;
        App.Host.Settings.Settings.StartWithWindows = AutostartToggle.IsOn;
        Save();
    }

    private void Tray_Toggled(object sender, RoutedEventArgs e)
    {
        if (_suppress) return;
        App.Host.Settings.Settings.MinimizeToTray = TrayToggle.IsOn;
        Save();
    }
}
