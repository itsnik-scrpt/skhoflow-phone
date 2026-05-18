using SkhoFlow.Host.Models;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace SkhoFlow.Host.Services;

/// <summary>
/// Stub host-side streaming pipeline.
///
/// The real implementation will:
///   1. Capture the desktop via Windows.Graphics.Capture (DirectX texture per frame)
///   2. Encode to H.264 / H.265 via Media Foundation transforms, preferring NVENC/AMF/QSV
///   3. Packetize into RTP/SRTP and send over UDP to the client's video port
///   4. Capture system audio via WASAPI loopback, encode to Opus, send over a second port
///   5. Receive input events (touch/gamepad) over WebSocket and synthesize via SendInput
///
/// For now this stub fires synthetic SessionStats so the UI can be exercised end-to-end.
/// </summary>
public sealed class StreamingHost : IStreamingHost, IDisposable
{
    private CancellationTokenSource? _cts;
    private Task? _loop;
    private SessionStats? _stats;
    private PairedDevice? _device;
    private StreamSettings? _settings;
    private DateTimeOffset _startedAt;

    public bool IsActive => _loop is { IsCompleted: false };
    public SessionStats? CurrentStats => _stats;

    public event EventHandler<SessionStats>? StatsUpdated;
    public event EventHandler<string>? StateChanged;

    public Task StartAsync(PairedDevice device, StreamSettings settings)
    {
        if (IsActive) return Task.CompletedTask;

        _device = device;
        _settings = settings;
        _startedAt = DateTimeOffset.UtcNow;
        _cts = new CancellationTokenSource();
        _loop = Task.Run(() => SimulateAsync(_cts.Token));

        StateChanged?.Invoke(this, "streaming");
        return Task.CompletedTask;
    }

    public Task StopAsync()
    {
        _cts?.Cancel();
        _stats = null;
        StateChanged?.Invoke(this, "idle");
        return Task.CompletedTask;
    }

    private async Task SimulateAsync(CancellationToken ct)
    {
        var rng = new Random();
        while (!ct.IsCancellationRequested)
        {
            _stats = new SessionStats
            {
                DeviceName = _device?.Name ?? "",
                Fps = _settings?.Fps ?? 60,
                LatencyMs = 8 + rng.Next(0, 10),
                BitrateKbps = (_settings?.BitrateKbps ?? 20000) + rng.Next(-1500, 1500),
                DroppedFrames = rng.NextDouble() < 0.02 ? 1 : 0,
                UptimeSeconds = (DateTimeOffset.UtcNow - _startedAt).TotalSeconds,
                Encoder = (_settings?.Encoder ?? EncoderKind.Auto).ToString(),
                Resolution = $"{_settings?.Width}x{_settings?.Height}",
            };
            StatsUpdated?.Invoke(this, _stats);

            try { await Task.Delay(500, ct); }
            catch { break; }
        }
    }

    public void Dispose() => StopAsync().GetAwaiter().GetResult();
}
