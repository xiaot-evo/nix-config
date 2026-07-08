{ den, ... }:
{
  den.aspects.dev.ai.ollama = {
    homeManager = { pkgs, ... }: {
      services.ollama = {
        enable = true;
        package = pkgs.ollama;
        host = "127.0.0.1";
        # GPU 加速（可选）：
        #   acceleration = "cuda";   # NVIDIA
        #   acceleration = "rocm";   # AMD
      };
      # 使用远程 Ollama 服务时，取消注释并填入服务器地址：
      # home.sessionVariables.OLLAMA_HOST = "http://your-server:11434";
    };
  };
}
