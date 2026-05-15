on alfred_script(q)
    do shell script "cd ~; nohup /Applications/Ghostty.app/Contents/MacOS/ghostty -e /bin/zsh -c \"source ~/.zshrc && " & q & ";/bin/zsh\" > /dev/null 2>&1 &"
end alfred_script
