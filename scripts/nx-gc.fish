# no shebang so i can run this on a pi without fish

# Delete stuff
nix-collect-garbage -d # user-collected garbage
sudo nix-collect-garbage -d

# Trim
sudo fstrim -av
