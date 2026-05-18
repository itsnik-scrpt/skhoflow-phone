using SkhoFlow.Host.Models;
using System;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace SkhoFlow.Host.Services;

/// <summary>
/// HTTP pairing + control endpoint.
///
/// GET  /info                   → host metadata
/// POST /pair    { name, model, pubKey, pin } → { deviceId } once the user approves the PIN
/// POST /unpair  { deviceId }
/// POST /session/start { deviceId } → { videoPort, controlPort, streamSettings }
/// POST /session/stop  { deviceId }
///
/// PINs are 6-digit codes generated on the host and shown in the UI;
/// the client must echo them back within 60 seconds.
/// </summary>
public sealed class PairingService : IDisposable
{
    private HttpListener? _listener;
    private CancellationTokenSource? _cts;
    private Task? _loop;
    private readonly SettingsStore _settings;
    private readonly Random _rng = new();

    public int Port { get; private set; } = 47990;
    public string HostId { get; } = Guid.NewGuid().ToString("N");
    public string? PendingPin { get; private set; }
    public DateTimeOffset PendingPinExpires { get; private set; }
    public string? PendingDeviceName { get; private set; }

    public event EventHandler<PairedDevice>? DevicePaired;
    public event EventHandler<string>? Log;

    public PairingService(SettingsStore settings) => _settings = settings;

    public void Start(int port)
    {
        Port = port;
        _listener = new HttpListener();
        _listener.Prefixes.Add($"http://+:{port}/");
        try
        {
            _listener.Start();
        }
        catch (HttpListenerException ex) when (ex.ErrorCode == 5)
        {
            // Access denied — fall back to loopback only. User can run as admin
            // or run `netsh http add urlacl` to widen.
            _listener = new HttpListener();
            _listener.Prefixes.Add($"http://127.0.0.1:{port}/");
            _listener.Prefixes.Add($"http://localhost:{port}/");
            _listener.Start();
            Log?.Invoke(this, "Pairing service bound to loopback only (add URL ACL to listen on LAN)");
        }

        _cts = new CancellationTokenSource();
        _loop = Task.Run(() => AcceptLoopAsync(_cts.Token));
        Log?.Invoke(this, $"Pairing service listening on :{port}");
    }

    public void Stop()
    {
        _cts?.Cancel();
        try { _listener?.Stop(); } catch { }
        _listener = null;
    }

    /// <summary>Generate a 6-digit PIN that the user reads from the Windows app and types in iOS.</summary>
    public string IssuePairingPin(TimeSpan? lifetime = null)
    {
        PendingPin = _rng.Next(0, 1_000_000).ToString("D6");
        PendingPinExpires = DateTimeOffset.UtcNow + (lifetime ?? TimeSpan.FromMinutes(2));
        return PendingPin;
    }

    public void CancelPendingPin()
    {
        PendingPin = null;
        PendingDeviceName = null;
    }

    private async Task AcceptLoopAsync(CancellationToken ct)
    {
        if (_listener == null) return;

        while (!ct.IsCancellationRequested && _listener.IsListening)
        {
            HttpListenerContext ctx;
            try { ctx = await _listener.GetContextAsync(); }
            catch { break; }

            _ = Task.Run(() => HandleAsync(ctx));
        }
    }

    private async Task HandleAsync(HttpListenerContext ctx)
    {
        try
        {
            switch (ctx.Request.Url?.AbsolutePath)
            {
                case "/info": await HandleInfoAsync(ctx); break;
                case "/pair": await HandlePairAsync(ctx); break;
                case "/unpair": await HandleUnpairAsync(ctx); break;
                case "/session/start": await HandleSessionStartAsync(ctx); break;
                case "/session/stop": await HandleSessionStopAsync(ctx); break;
                default: await WriteJsonAsync(ctx, 404, new { error = "not_found" }); break;
            }
        }
        catch (Exception ex)
        {
            Log?.Invoke(this, $"Pairing handler error: {ex.Message}");
            try { await WriteJsonAsync(ctx, 500, new { error = "internal" }); } catch { }
        }
    }

    private async Task HandleInfoAsync(HttpListenerContext ctx)
    {
        await WriteJsonAsync(ctx, 200, new
        {
            id = HostId,
            name = _settings.Settings.HostName,
            version = 2,
            requirePin = _settings.Settings.RequirePin,
            protocol = "skhoflow/2.0",
        });
    }

    private async Task HandlePairAsync(HttpListenerContext ctx)
    {
        if (ctx.Request.HttpMethod != "POST")
        { await WriteJsonAsync(ctx, 405, new { error = "method" }); return; }

        var bodyOpt = await ReadBodyAsync(ctx);
        if (bodyOpt is not { } body) { await WriteJsonAsync(ctx, 400, new { error = "bad_body" }); return; }

        var name = body.GetProperty("name").GetString() ?? "iPhone";
        var model = body.TryGetProperty("model", out var m) ? m.GetString() ?? "" : "";
        var pubKey = body.TryGetProperty("publicKey", out var k) ? k.GetString() ?? "" : "";
        var pin = body.TryGetProperty("pin", out var p) ? p.GetString() ?? "" : "";

        if (_settings.Settings.RequirePin)
        {
            if (PendingPin == null || DateTimeOffset.UtcNow > PendingPinExpires)
            { await WriteJsonAsync(ctx, 403, new { error = "no_pin_pending" }); return; }

            if (!CryptographicOperations.FixedTimeEquals(
                    Encoding.UTF8.GetBytes(pin),
                    Encoding.UTF8.GetBytes(PendingPin)))
            { await WriteJsonAsync(ctx, 403, new { error = "wrong_pin" }); return; }
        }

        var device = new PairedDevice
        {
            Name = name,
            Model = model,
            PublicKeyBase64 = pubKey,
        };

        _settings.AddOrUpdateDevice(device);
        CancelPendingPin();
        DevicePaired?.Invoke(this, device);

        await WriteJsonAsync(ctx, 200, new { deviceId = device.Id });
    }

    private async Task HandleUnpairAsync(HttpListenerContext ctx)
    {
        var body = await ReadBodyAsync(ctx);
        var id = body?.GetProperty("deviceId").GetString() ?? "";
        if (string.IsNullOrEmpty(id))
        { await WriteJsonAsync(ctx, 400, new { error = "bad_body" }); return; }

        _settings.RemoveDevice(id);
        await WriteJsonAsync(ctx, 200, new { ok = true });
    }

    private async Task HandleSessionStartAsync(HttpListenerContext ctx)
    {
        var body = await ReadBodyAsync(ctx);
        var id = body?.GetProperty("deviceId").GetString() ?? "";
        if (string.IsNullOrEmpty(id))
        { await WriteJsonAsync(ctx, 400, new { error = "bad_body" }); return; }

        var device = _settings.Devices.Find(d => d.Id == id);
        if (device == null)
        { await WriteJsonAsync(ctx, 404, new { error = "not_paired" }); return; }

        var s = _settings.Settings.Stream;
        await WriteJsonAsync(ctx, 200, new
        {
            videoPort = s.Port,
            controlPort = s.ControlPort,
            stream = new
            {
                width = s.Width,
                height = s.Height,
                fps = s.Fps,
                bitrateKbps = s.BitrateKbps,
                codec = s.Codec.ToString().ToLowerInvariant(),
                audioBitrateKbps = s.AudioBitrateKbps,
            },
        });
    }

    private async Task HandleSessionStopAsync(HttpListenerContext ctx)
    {
        await WriteJsonAsync(ctx, 200, new { ok = true });
    }

    private static async Task<JsonElement?> ReadBodyAsync(HttpListenerContext ctx)
    {
        using var reader = new StreamReader(ctx.Request.InputStream, Encoding.UTF8);
        var body = await reader.ReadToEndAsync();
        if (string.IsNullOrWhiteSpace(body)) return null;
        try
        {
            using var doc = JsonDocument.Parse(body);
            return doc.RootElement.Clone();
        }
        catch { return null; }
    }

    private static async Task WriteJsonAsync(HttpListenerContext ctx, int status, object payload)
    {
        ctx.Response.StatusCode = status;
        ctx.Response.ContentType = "application/json";
        var bytes = JsonSerializer.SerializeToUtf8Bytes(payload);
        await ctx.Response.OutputStream.WriteAsync(bytes);
        ctx.Response.Close();
    }

    public void Dispose() => Stop();
}
