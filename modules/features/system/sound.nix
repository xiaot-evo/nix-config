# 音频：PipeWire 音视频框架
# 同时启用 ALSA（含 32 位支持）和 PulseAudio 兼容层
{ den, ... }:
{
  den.aspects.system.sound = {
    nixos.services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
