using System;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace SkhoFlow.Host.Services;

/// <summary>
/// Lightweight LAN discovery: answers UDP broadcast probes from iOS clients
/// with this host's name, port, and a stable id. Uses port 47988 by convention.
/// This is a substitute for full mDNS until we wire Bonjour-equivalent on Windows.
/// </summary>
public sealed class DiscoveryService : IDisposable
{
    private const int DiscoveryPort = 47988;
    private const string Magic = "SKHO?";
    private const string ReplyMagic = "SKHO!";

    private UdpClient? _udp;
    private CancellationTokenSource? _cts;
    private Task? _loop;
    private string _hostId = Guid.NewGuid().ToString("N");
    private string _hostName = Environment.MachineName;
    private int _controlPort = 47990;

    public bool IsRunning { get; private set; }

    public void Start(string hostName, int controlPort, string hostId)
    {
        if (IsRunning) return;

        _hostName = hostName;
        _controlPort = controlPort;
        _hostId = hostId;

        _udp = new UdpClient(DiscoveryPort) { EnableBroadcast = true };
        _cts = new CancellationTokenSource();
        _loop = Task.Run(() => ReceiveLoopAsync(_cts.Token));
        IsRunning = true;
    }

    public void Stop()
    {
        if (!IsRunning) return;
        _cts?.Cancel();
        _udp?.Close();
        _udp = null;
        IsRunning = false;
    }

    private async Task ReceiveLoopAsync(CancellationToken ct)
    {
        if (_udp == null) return;

        while (!ct.IsCancellationRequested)
        {
            try
            {
                var result = await _udp.ReceiveAsync(ct);
                var text = Encoding.UTF8.GetString(result.Buffer);
                if (!text.StartsWith(Magic, StringComparison.Ordinal)) continue;

                var reply = JsonSerializer.SerializeToUtf8Bytes(new
                {
                    type = ReplyMagic,
                    id = _hostId,
                    name = _hostName,
                    port = _controlPort,
                    version = 2,
                });

                await _udp.SendAsync(reply, reply.Length, result.RemoteEndPoint);
            }
            catch (OperationCanceledException) { break; }
            catch { /* swallow; keep listening */ }
        }
    }

    /// <summary>Returns the first non-loopback IPv4 address, useful to display in the UI.</summary>
    public static string GetLocalIPv4()
    {
        foreach (var ni in NetworkInterface.GetAllNetworkInterfaces())
        {
            if (ni.OperationalStatus != OperationalStatus.Up) continue;
            if (ni.NetworkInterfaceType == NetworkInterfaceType.Loopback) continue;

            foreach (var ip in ni.GetIPProperties().UnicastAddresses)
            {
                if (ip.Address.AddressFamily == AddressFamily.InterNetwork &&
                    !IPAddress.IsLoopback(ip.Address))
                {
                    return ip.Address.ToString();
                }
            }
        }
        return "0.0.0.0";
    }

    public void Dispose() => Stop();
}
