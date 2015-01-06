echo "downloading shell-tanks tarball to $HOME/.s.tar.gz..."
curl -# "boozon.net/st/shell-tanks.tar.gz" > "$HOME/.s.tar.gz"
echo "done, making directory $HOME/.shell-tanks..."
mkdir "$HOME/.shell-tanks"
cd "$HOME/.shell-tanks"
echo "extracting tarball into shell-tanks..."
tar -xf "../.s.tar.gz"
echo "removing tarball..."
rm "../.s.tar.gz"
echo "installed, placing launch shortcut $HOME/shell-tanks"
echo "cd ~/.shell-tanks/bin&&bash run.sh" > ~/shell-tanks
chmod +x ~/shell-tanks
echo "run $HOME/shell-tanks to play"