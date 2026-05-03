{ pkgs, inputs, ... }:
{
   imports = [ inputs.areofyl-fetch.homeManagerModules.default ];

	programs.fetch = {
	enable = true;
	labelColor = "red";
	info = ["host" "os" "kernel" "uptime" "packages" "shell" "memory"];
	speed = 1.0;
	spin = "xy";
};
}
