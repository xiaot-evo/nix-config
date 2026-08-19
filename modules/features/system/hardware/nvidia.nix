# NVIDIA Optimus 混合显卡配置（NVIDIA + AMDGPU）
# 参数 nvidiaBusId / amdgpuBusId：由调用方提供 PCI Bus ID
{ den, ... }:

{
  den.aspects.system.hardware.nvidia =
    { nvidiaBusId, amdgpuBusId }:
    {
      includes = [
        (den.batteries.unfree [
          "nvidia-x11"
          "nvidia-settings"
        ])
      ];
      nixos =
        { config, ... }:
        {
          # 启用图形支持（含 VA-API/VDPAU）
          hardware.graphics.enable = true;

          # 注意：nixpkgs 的 hardware.nvidia 模块整体以 videoDrivers 含 "nvidia"
          # 为启用条件（cfg.enable = elem "nvidia" ...），同时满足
          # nvidia-container-toolkit 的驱动断言。虽为纯 Wayland（无 Xorg server），
          # 此设置驱动整个 NVIDIA 用户态栈（nvidia-offload、nvidia-settings、
          # EGL external platform、VAAPI 等），不可移除
          services.xserver.videoDrivers = [
            "amdgpu"
            "nvidia"
          ];

          hardware.nvidia = {
            modesetting.enable = true;
            powerManagement.enable = false;
            powerManagement.finegrained = true;
            open = true; # 开源内核模块 (nvidia-open)
            nvidiaSettings = true; # 提供 nvidia-settings GUI
            package = config.boot.kernelPackages.nvidiaPackages.stable;
          };

          # Prime Render Offload：默认用 AMDGPU 渲染，NVIDIA 按需调用
          hardware.nvidia.prime = {
            offload = {
              enable = true;
              enableOffloadCmd = true;
            };
            nvidiaBusId = nvidiaBusId;
            amdgpuBusId = amdgpuBusId;
          };
        };
    };
}
