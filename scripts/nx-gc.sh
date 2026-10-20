# Delete stuff
nix-collect-garbage -d # user-collected garbage
sudo nix-collect-garbage -d

# Trim
sudo fstrim -av
