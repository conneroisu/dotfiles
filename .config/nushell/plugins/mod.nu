# if clipboard is not executable, run:

if ! command -v nu_plugin_clipboard &> /dev/null; then

e

git clone https://github.com/FMotalleb/nu_plugin_clipboard.git
nupm install --path nu_plugin_clipboard -f
