using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using SkhoFlow.Host.Services;
using System;
using System.Threading.Tasks;

namespace SkhoFlow.Host.Pages;

public sealed partial class HomePage : Page
{
    public HomePage()
    {
        InitializeComponent();
        Loaded += OnLoaded;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        var s = App.Host.Settings.Settings;
        HostNameText.Text = s.HostName;
        IpAddressText.Text = DiscoveryService.GetLocalIPv4();
        PortText.Text = s.Stream.ControlPort.ToString();
        ResolutionText.Text = $"{s.Stream.Height}p";
        FpsText.Text = $"{s.Stream.Fps} fps";
        BitrateText.Text = (s.Stream.BitrateKbps / 1000).ToString();
        EncoderText.Text = s.Stream.Encoder.ToString();
        PairedCountText.Text = App.Host.Settings.Devices.Count.ToString();
    }

    private async void StartHosting_Click(object sender, RoutedEventArgs e)
    {
        if (App.Host.Streaming.IsActive)
        {
            await App.Host.Streaming.StopAsync();
            return;
        }

        if (App.Host.Settings.Devices.Count == 0)
        {
            await ShowDialogAsync("No paired devices", "Pair an iPhone first, then start hosting.");
            return;
        }

        var device = App.Host.Settings.Devices[0];
        await App.Host.Streaming.StartAsync(device, App.Host.Settings.Settings.Stream);
    }

    private async void PairDevice_Click(object sender, RoutedEventArgs e)
    {
        var pin = App.Host.Pairing.IssuePairingPin();
        await ShowDialogAsync(
            "Pair an iPhone",
            $"Open SkhoFlow on your iPhone, pick this host, and enter:\n\n{pin}\n\nThe code expires in 2 minutes.");
    }

    private Task ShowDialogAsync(string title, string body)
    {
        var dialog = new ContentDialog
        {
            Title = title,
            Content = body,
            CloseButtonText = "OK",
            XamlRoot = this.XamlRoot,
        };
        return dialog.ShowAsync().AsTask();
    }
}
