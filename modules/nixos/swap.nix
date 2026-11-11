{ ... }:
{
  zramSwap = {
    enable = true;
    memoryPercent = 100;
    algorithm = "lz4";
    priority = 100;
  };

  swapDevices = [
    {
        device = "/swapfile";
        size = 8 * 1024;
        priority = 10;
      }
  ];
}
