defmodule NxAudio.Transforms.Spectrogram do
  @moduledoc """
  Spectrogram transformation for audio tensors.
  """
  @moduledoc section: :transforms

  import Nx.Defn
  import NxAudio.Transforms.SpectrogramConfig

  @behaviour NxAudio.Transforms

  @doc """
  Computes the spectrogram of an audio signal.  

  Args:  
    audio_tensor: Input audio tensor of shape [samples] or [channels, samples]  
    config: Spectrogram configuration options `NxAudio.Transforms.SpectrogramConfig`  

  Returns:  
    If input is [samples]: Returns tensor of shape [time, frequency]  
    If input is [channels, samples]: Returns tensor of shape [channels, time, frequency]  

  Note:  
    Expected input format is {channels, time} for multi-channel audio  
  """

  @impl true
  @spec transform(NxAudio.IO.audio_tensor(), NxAudio.Transforms.SpectrogramConfig.t()) ::
          NxAudio.IO.audio_tensor()
  defn transform(audio_tensor, opts \\ []) do
    opts = validate(opts)

    # Store original rank
    original_rank = Nx.rank(audio_tensor)

    audio_tensor = maybe_add_channel_dim(audio_tensor)
    win_length = maybe_calculate_win_length(opts[:win_length], opts[:n_fft])
    hop_length = maybe_calculate_hop_length(opts[:hop_length], win_length)
    window = opts[:window_fn].(window_length: win_length, periodic: true)

    result =
      audio_tensor
      |> maybe_center_pad(opts)
      |> maybe_additional_pad(opts)
      |> create_frames(win_length, hop_length)
      |> apply_window(window)
      |> compute_fft(opts[:n_fft], opts[:onesided])
      |> handle_normalization(window, win_length, opts)
      |> return_power_or_magnitude(opts)

    if original_rank == 1, do: Nx.squeeze(result, axes: [0]), else: result
  end

  defnp maybe_add_channel_dim(tensor) do
    case Nx.rank(tensor) do
      1 ->
        size = Nx.size(tensor)
        Nx.reshape(tensor, {1, size})

      _ ->
        tensor
    end
  end

  defnp maybe_center_pad(tensor, opts) do
    if opts[:center] do
      pad_size = div(opts[:n_fft], 2)

      padding =
        if Nx.rank(tensor) == 1, do: [{pad_size, pad_size}], else: [{0, 0}, {pad_size, pad_size}]

      case opts[:pad_mode] do
        :reflect -> Nx.pad_outer(tensor, :reflect, padding)
        _ -> Nx.pad(tensor, 0, padding_config: padding)
      end
    else
      tensor
    end
  end

  defnp maybe_additional_pad(tensor, opts) do
    if opts[:pad] > 0 do
      padding =
        if Nx.rank(tensor) == 1,
          do: [{opts[:pad], opts[:pad]}],
          else: [{0, 0}, {opts[:pad], opts[:pad]}]

      case opts[:pad_mode] do
        :reflect -> Nx.pad_outer(tensor, :reflect, padding)
        _ -> Nx.pad(tensor, 0, padding_config: padding)
      end
    else
      tensor
    end
  end

  defnp create_frames(input, frame_length, hop_length) do
    {_n_channels, n_samples} = Nx.shape(input)
    n_frames = div(n_samples - frame_length, hop_length) + 1

    # Create frame indices for each channel
    indices =
      Nx.iota({frame_length})
      |> Nx.add(Nx.multiply(Nx.reshape(Nx.iota({n_frames}), {n_frames, 1}), hop_length))
      |> Nx.new_axis(0)

    # Gather frames for each channel
    {n_channels, _} = Nx.shape(input)

    input
    |> Nx.new_axis(1)
    |> Nx.broadcast({n_channels, n_frames, n_samples})
    |> Nx.take_along_axis(indices, axis: 2)
  end

  defnp apply_window(frames, window) do
    {_n_channels, _n_frames, frame_length} = Nx.shape(frames)
    window = Nx.reshape(window, {1, 1, frame_length})
    Nx.multiply(frames, window)
  end

  defnp compute_fft(frames, fft_size, onesided?) do
    result = Nx.fft(frames, length: fft_size)

    if onesided? do
      n_freqs = div(fft_size, 2) + 1
      {n_channels, n_frames, _} = Nx.shape(result)
      Nx.slice(result, [0, 0, 0], [n_channels, n_frames, n_freqs])
    else
      result
    end
  end

  defnp handle_normalization(spec, window, frame_length, opts) do
    case opts[:normalized] do
      :window -> Nx.divide(spec, Nx.sum(window))
      :frame_length -> Nx.divide(spec, frame_length)
      _ -> spec
    end
  end

  defnp return_power_or_magnitude(spec, opts) do
    if opts[:power] != -1 do
      spec
      |> complex_abs()
      |> Nx.pow(opts[:power])
    else
      spec
    end
  end

  defnp complex_abs(x) do
    Nx.sqrt(Nx.add(Nx.pow(Nx.real(x), 2), Nx.pow(Nx.imag(x), 2)))
  end
end
