#!/bin/sh

SCREENRC='
# GNU Screen - main configuration file
# All other .screenrc files will source this file to inherit settings.
# Author: Christian Wills - cwills.sys@gmail.com
# https://gist.github.com/ChrisWills/1337178

backtick 101 10 10 hostname -I

# Allow bold colors - necessary for some reason
attrcolor b ".I"

# Tell screen how to set colors. AB = background, AF=foreground
termcapinfo xterm "Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm"

# Enables use of shift-PgUp and shift-PgDn
termcapinfo xterm|xterms|xs|rxvt ti@:te@

# Erase background with current bg color
defbce "on"

# Enable 256 color term
term xterm-256color

# Cache 30000 lines for scroll back
defscrollback 30000

hardstatus alwayslastline
# Very nice tabbed colored hardstatus line with datetime, hostname and ip addresses
hardstatus string '"'"'%{= Kd} %{= Kd}%-w%{= Kr}[%{= KW}%n %t%{= Kr}]%{= Kd}%+w %-= %{KG} %H%{KW}|%{KY} %101`%{KW}|%D %M %d %Y%{= KY} %c%{-}'"'"'

# kill startup splash
startup_message off
'

MC_INI='
[Midnight-Commander]
verbose=true
shell_patterns=true
auto_save_setup=true
preallocate_space=false
auto_menu=false
use_internal_view=true
use_internal_edit=false
clear_before_exec=true
confirm_delete=true
confirm_overwrite=true
confirm_execute=false
confirm_history_cleanup=true
confirm_exit=false
confirm_directory_hotlist_delete=false
confirm_view_dir=false
safe_delete=false
safe_overwrite=false
use_8th_bit_as_meta=false
mouse_move_pages_viewer=true
mouse_close_dialog=false
fast_refresh=false
drop_menus=false
wrap_mode=true
old_esc_mode=true
cd_symlinks=true
show_all_if_ambiguous=false
use_file_to_guess_type=true
alternate_plus_minus=false
only_leading_plus_minus=true
show_output_starts_shell=false
xtree_mode=false
file_op_compute_totals=true
classic_progressbar=true
use_netrc=true
ftpfs_always_use_proxy=false
ftpfs_use_passive_connections=true
ftpfs_use_passive_connections_over_proxy=false
ftpfs_use_unix_list_options=true
ftpfs_first_cd_then_ls=true
ignore_ftp_chattr_errors=true
editor_fill_tabs_with_spaces=false
editor_return_does_auto_indent=false
editor_backspace_through_tabs=false
editor_fake_half_tabs=true
editor_option_save_position=true
editor_option_auto_para_formatting=false
editor_option_typewriter_wrap=false
editor_edit_confirm_save=true
editor_syntax_highlighting=true
editor_persistent_selections=true
editor_drop_selection_on_copy=true
editor_cursor_beyond_eol=false
editor_cursor_after_inserted_block=false
editor_visible_tabs=true
editor_visible_spaces=true
editor_line_state=false
editor_simple_statusbar=false
editor_check_new_line=false
editor_show_right_margin=false
editor_group_undo=true
editor_state_full_filename=true
editor_ask_filename_before_edit=false
nice_rotating_dash=true
mcview_remember_file_position=false
auto_fill_mkdir_name=true
copymove_persistent_attr=true
pause_after_run=1
mouse_repeat_rate=100
double_click_speed=250
old_esc_mode_timeout=1000000
max_dirt_limit=10
num_history_items_recorded=60
vfs_timeout=60
ftpfs_directory_timeout=900
ftpfs_retry_seconds=30
fish_directory_timeout=900
editor_tab_spacing=8
editor_word_wrap_line_length=72
editor_option_save_mode=0
editor_backup_extension=~
editor_filesize_threshold=64M
editor_stop_format_chars=-+*\\,.;:&>
mcview_eof=
skin=nicedark

[Layout]
message_visible=0
keybar_visible=0
xterm_title=1
output_lines=0
command_prompt=0
menubar_visible=0
free_space=1
horizontal_split=0
vertical_equal=1
left_panel_size=40
horizontal_equal=1
top_panel_size=1

[Misc]
timeformat_recent=%b %e %H:%M
timeformat_old=%b %e  %Y
ftp_proxy_host=gate
ftpfs_password=anonymous@
display_codepage=ASCII
source_codepage=Other_8_bit
autodetect_codeset=
spell_language=en
clipboard_store=
clipboard_paste=

[Colors]
base_color=
xterm-256color=
color_terminals=

[Panels]
show_mini_info=true
kilobyte_si=false
mix_all_files=false
show_backups=true
show_dot_files=true
fast_reload=false
fast_reload_msg_shown=false
mark_moves_down=true
reverse_files_only=true
auto_save_setup_panels=false
navigate_with_arrows=true
panel_scroll_pages=true
panel_scroll_center=false
mouse_move_pages=true
filetype_mode=true
permission_mode=false
torben_fj_mode=false
quick_search_mode=2
select_flags=6

simple_swap=false

[Panelize]
Find *.orig after patching=find . -name \\*.orig -print
Find SUID and SGID programs=find . \\( \\( -perm -04000 -a -perm /011 \\) -o \\( -perm -02000 -a -perm /01 \\) \\) -print
Find rejects after patching=find . -name \\*.rej -print
Modified git files=git ls-files --modified
'

#########################################################################################################################
#########################################################################################################################
#########################################################################################################################

echo 'Raspberry console env setup. Network has to be set up at this point.'
echo ''

NO_USER=0
if [ '--no-user' = "$1" ]; then
	NO_USER=1
fi

echo -n 'Hostname: '
read HOSTNAME
OLD_HOSTNAME=`hostname`

# validate if the given hostname could be set as static hostname (it will go to /etc/hostname)
if sudo hostnamectl --no-ask-password set-hostname "$HOSTNAME" --static; then
    # Set hostname to /etc/hosts to prevent "unable to resolve host" warning
    sudo sed -ie "s/$OLD_HOSTNAME/$HOSTNAME/g" /etc/hosts
    # Set new hostname via hostnamectl (will be accessible in /etc/hostname)
    # (with the option --static hostnamectl will change only the static hostname, not the pretty one, so update it here)
    sudo hostnamectl --no-ask-password set-hostname "$HOSTNAME"
else
    echo "Hostname validation failed"
    exit 1
fi

echo -n 'Username: '
read USERNAME
if [ "$NO_USER" -ne 1 ]; then
	add_groups() {
		while [ $# -gt 0 ]; do
			sudo adduser "$USERNAME" "$1"
			shift
		done
	}
	sudo adduser --disabled-password --gecos "" "$USERNAME" || exit 1
	add_groups sudo adm users dialout cdrom audio video plugdev games input netdev gpio i2c spi
	sudo passwd "$USERNAME" || exit 1
fi

echo 'Upgrading system...'
sudo apt-get update
sudo apt-get -y upgrade

echo 'Installing stuff...'
sudo apt-get -y install screen mc vim zsh git lynx elinks dnsutils nmap htop

echo 'Setup environment...'
# _unquoted_ tilde for home directory, will instantly transform into fullpath
#HOME=~
HOME="/home/$USERNAME"

echo "$SCREENRC" | sudo -u "$USERNAME" tee "$HOME/.screenrc" > /dev/null
sudo -u "$USERNAME" mkdir -p "$HOME/.config/mc"
echo "$MC_INI" |sudo -u "$USERNAME" tee "$HOME/.config/mc/ini" > /dev/null

ZSH="$HOME/.oh-my-zsh"
ZSHRC="$HOME/.zshrc"
sudo -u "$USERNAME" git clone --depth=1 --branch "master" "https://github.com/robbyrussell/oh-my-zsh.git" "$ZSH" || {
                echo "error: git clone of oh-my-zsh repo failed"
        }
# create custom theme from flazz to remove unicode symbols because of stupid fucking Konsole >_<
if [ ! -e "$ZSH/themes/flazz-no-utf.zsh-theme" ]; then
	THEME="$ZSH/themes/flazz-no-utf.zsh-theme"
	sudo -u "$USERNAME" cp "$ZSH/themes/flazz.zsh-theme" "$THEME"
	sudo -u "$USERNAME" sed -i 's|^local return_code=.\+|local return_code="%(?..%{$fg[red]%}%? %{$reset_color%})"|g' "$THEME"
fi
# initialize zshrc
sudo -u "$USERNAME" cp "$ZSH/templates/zshrc.zsh-template" "$ZSHRC"
sudo -u "$USERNAME" sed -i "s|^ZSH_THEME=.\+$|ZSH_THEME=\"flazz-no-utf\"|g" "$ZSHRC"
sudo -u "$USERNAME" sed -i "s|^.*DISABLE_AUTO_UPDATE=.\+$|DISABLE_AUTO_UPDATE=\"true\"|g" "$ZSHRC"
sudo -u "$USERNAME" sed -i "s|^.*COMPLETION_WAITING_DOTS=.\+$|COMPLETION_WAITING_DOTS=\"true\"|g" "$ZSHRC"
# make htop showing thread names
sudo -u "$USERNAME" sed -i "s|^show_thread_names=0|show_thread_names=1|g" "$HOME/.config/htop/htoprc"
# add screen start for current user
echo "" | sudo -u "$USERNAME" tee -a "$HOME/.zshrc" > /dev/null
echo 'if [[ $STY = "" ]] then screen -xR lt; fi' | sudo -u "$USERNAME" tee -a "$HOME/.zshrc" > /dev/null
# upgrade ownership
#echo 'Fixing ownership...'
#sudo chown -R "$USERNAME:$USERNAME" "$HOME"
# switch user whell to zsh
sudo chsh -s "/bin/zsh" "$USERNAME"
echo 'Expiring user pi...'
sudo chage -E0 pi
echo "Done. User pi is expired now, pls log out and log in as user $USERNAME"
