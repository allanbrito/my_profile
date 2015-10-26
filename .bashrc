						############################################################################################
						# 						           @author Allan Brito                                     #
						#  Se a váriável atualiza_bashrc estiver setada com true, qualquer alteração será perdida  #
						############################################################################################

#variables
now=$(date +"%Y%m%d_%H%M")
windows=false
linux=false
mac=false
path_root=/var/www
whoami=$(id -u -n)
path_config=~/.bashconfig
path_profile=~/my_bash
wiki_url="http://fabrica.moobitech.com.br/w/scripts_no_bash/"
default_params="atualiza_bashrc=true
mostrar_mensagem_ultimo_commit=true
baixa_por_ssh=false
local_host=192.168.25.200
local_user=root
local_pass=
remote_host=sindicalizi.com.br
remote_user=sindical
remote_pass="
use_database=

# PS1="\n\[\e[1;30m\][$$:$PPID - \j:\!\[\e[1;30m\]]\[\e[0;36m\] \T \[\e[1;30m\][\[\e[1;34m\]\u@\H\[\e[1;30m\]:\[\e[0;37m\]${SSH_TTY:-o} \[\e[0;32m\]+${SHLVL}\[\e[1;30m\]] \[\e[1;37m\]\w\[\e[0;37m\] \n\$ "

#atalhos
alias ls='ls -F --show-control-chars'
alias gts='git status '
alias e='exit'
alias mysql=mysql
alias mysqldump=mysqldump
alias php=php

#exec
function config_reset {
	(touch "$path_config" && echo "$default_params" > "$path_config" && config)
}

function config {
	vim "$path_config"
}
clear
set -o noglob

#iniciar arquivo de configuração
mkdir -p "$path_profile"
( [ -f "$path_config" ] || config_reset)
eval "$default_params"
while read linha 
do
    eval "$linha"
done < "$path_config"
case "$(uname -s)" in
	Darwin)
		mac=true
	;;
	Linux)
		linux=true
	;;
	CYGWIN*|MINGW32*|MSYS*)
		windows=true
		path_root=/c/xampp/htdocs
		alias mysql=$path_root/../mysql/bin/mysql.exe
		alias mysqldump=$path_root/../mysql/bin/mysqldump.exe
		alias php=$path_root/../php/php.exe
	;;
esac

#alias || variables pt2
migrations=$path_root/sindicalizi/migrations/
alias moobidb=$path_root/sindicalizi/moobilib/scripts/moobidb.php

#auto_update
function bash_commit {
	# read -r -p "Deseja atualizar as funções? [S/n] " response
	clear
	read -r -p "Existem alterações, deseja [V]er ou [C]ommitar? [C/v/*] " response
	case $response in
		[cC])
			local path="${PWD##/}"
			read -r -p "Mensagem do commit: " msg
			msg=${msg:-bash_update}
			cd "$path_profile"
			cp ../.bashrc .bashrc
			git add .
			git commit -am "$msg"
			bash_update_version
			git pull origin master && 
			git push origin master
			cd "/$path"
		;;
		[vV])
			git diff --no-index -- "$path_profile"/.bashrc "$path_profile"/../.bashrc
			bash_commit
		;;
		"")
			bash_commit
		;;
	esac 
}

function bash_update_version {
	( [ -f ~/.version ] || touch ~/.version) && echo $(date -d '-1 min' '+%Y-%m-%dT%H:%M') > ~/.version
}

function use {
	use_database="$1"
}

function wiki {
	if [[ "$windows" == true ]] ; then
		start "$wiki_url"
	else 
		if [[ "$mac" == true ]] ; then
			open "$wiki_url"
		else
			xdg-open "$wiki_url"
		fi
	fi
}


function bash_init {
	if [ ! -d "$path_profile"/.git ]; then
		git -C "$path_profile" init 
		git -C "$path_profile" remote add origin https://github.com/allanbrito/my_profile.git 
		git -C "$path_profile" fetch --all
		git -C "$path_profile" pull origin master
		bash_update_version
		cp "$path_profile"/.bashrc "$path_profile"/../.bashrc
	fi
}

function bash_reset {
		clear
	if [[ "$windows" == true ]] ; then
		"C:\Program Files (x86)\Git\bin\sh.exe" --login -i
	fi
}
alias reset=bash_reset

function bash_update {
	git -C "$path_profile" fetch
	if [[ $(git -C "$path_profile" rev-parse HEAD) != $(git -C "$path_profile" rev-parse origin/master) ]]; then
		read -r -p "Deseja atualizar as funções? [S/n] " response
		case $response in
			[sS][iI][mM]|[sS])
				cd "$path_profile"
				git pull origin master
				cp .bashrc ../.bashrc
				bash_reset
			;;
		esac
	fi	
}

function bash_changelog {
	local lines="$@"
	local message=$(git -C "$path_profile" log ${lines:--10} | cat)
	[[ ${#message} != 0 ]] && echo "Últimas mudanças:" && git -C "$path_profile" log "${lines:--10}" --pretty=format:"%C(white bold) %s %C(reset)%C(bold)%C(yellow ul)<%an, %ar>%C(reset)" | cat
	echo -C "$path_profile" log "${lines:--10}" --pretty=format:"%C(white bold) %s %C(reset)%C(bold)%C(yellow ul)<%an, %ar>%C(reset)"
	if [[ $lines != "" ]]; then
		bash_update_version
	fi

}

if [[ "$atualiza_bashrc" == true ]] ; then
	bash_init 
	if [[ $(diff "$path_profile"/.bashrc "$path_profile"/../.bashrc) ]]; then 
		bash_commit
	else 
		bash_update
	fi
	clear
fi

if [[ "$mostrar_mensagem_ultimo_commit" == true ]] ; then
	# echo $(git -C ~/my_bash/ log  @{1}.. --reverse --no-merges)
	# echo $(git -C "$path_profile" log -1 --pretty=format:"%C(bold)%s %C(bold)%C(Yellow ul)%an, %ar")
	bash_changelog $(echo "--after='"$(cat ~/.version)"'" || echo "-1")
fi

function sublime_commit {
	local path="${PWD##/}"
	tar -zcvf "$path_profile"/Sublime_"$whoami".tar.gz -C ~/AppData/Roaming/Sublime\ Text\ 3/ Packages Installed\ Packages
	read -r -p "Deseja commitar? [S/n] " response
	case $response in
		[sS][iI][mM]|[sS])
			git -C "$path_profile" add .
			git -C "$path_profile" commit -am "Sublime preferences"
			git -C "$path_profile" pull origin master
			git -C "$path_profile" push
		;;
	esac

}

function sublime_update {
	local user="$1"
	if [[ "$user" == "" ]] ; then
		user="$whoami"
	fi
	if [[ ! -f "$path_profile"/Sublime_"$user".tar.gz ]]; then
		echo "O sublime de $user não está disponível"
	else
		tar -zxvf  "$path_profile"/Sublime_"$user".tar.gz -C ~/AppData/Roaming/Sublime\ Text\ 3/
		clear
		echo "Sublime atualizado para o de ${user}!"
	fi
}

#functions
function mysql_local {
	local host="$local_host"
	local user="$local_user"
	local pass="$local_pass"
	local banco
	local mysql_commands=("select" "update" "delete" "alter" "show" "desc" "create" "drop" "describe" "flush")

	if [[ "$1" == "-r" ]] ; then
		host="$remote_host"
		user="$remote_user"
		pass="$remote_pass"
		shift
	fi

	connection="-u $user -h $host -p$pass"
	if [[ "$2" == "" ]] ; then
		mysql $connection sindical_${use_database:-$1} || mysql $connection
	else
		if [[ "$use_database" == "" ]] ; then
			banco="$1"
			shift
		else 
			if [[ $(echo "${mysql_commands[@]}" | grep "$1" | wc -w) -eq 0 ]]; then
				banco="$1"
				shift
			else
				banco="$use_database"
			fi
		fi
		local sql=$@
		if [[ -f $@ ]]; then
			sql="source ${sql/~/\~}"
		fi
		mysql $connection sindical_$banco -e "$sql" || mysql $connection
	fi
}
alias m=mysql_local

function mysql_remote {
	mysql_local -r "$@"
}
alias s=mysql_remote

function path_root {
	cd $path_root/"$1"
}
alias x=path_root

function git_commit {
	local update=true
	local mensagem=
	while [ "$1" != "" ]; do
		case $1 in
			-e)
				update=false
			;;
			* )	
				mensagem="$mensagem $1"
			;;
		esac
		shift
	done
	if [[ $mensagem != "" ]]; then
		git add . 
		git commit -am "$mensagem" || true 
		git pull 
		git push 
		if [[ $update == true ]]; then
			git_update
		fi
	fi
}
alias gtc="git_commit --"

function git_update {
	local path="${PWD##/}"
	if [[ -d "sisfinanc" ]]; then
		echo "  sisfinanc, env e var:"
		cd sisfinanc 
		git pull || true
	else
		echo "  env e var:"
	fi
	x env 
	git pull || true 
	x var 
	git pull || true 
	cd "/$path"
}
alias gtu=git_update

function migration {
	moobidb --no-ansi "$@"
}

function migration_local_todas {
	migration --migrate --all "$@"
}
alias migrate=migration_local_todas

function migration_remote_todas {
	migration --migrate --prod --all "$@"
}
alias migrates=migration_remote_todas

function migration_create {
	if [[ "$1" != "" ]] ; then
		local hora=$(date +"%Y%m%d%H%M")
		echo migration "$hora"_"$1".sql criada
		touch $migrations/"$hora"_"$1".sql
		if [[ "$2" != "" ]] ; then
			local nome="$hora"_"$1".sql
			read -r -p "Deseja marcar a migration \"$nome\" no banco \"$2\" local? [S/n] " response
			case $response in
				[sS][iI][mM]|[sS])
					migration -s "$2" --mark "$hora"_"$1".sql
				;;
			esac
		fi
	fi
}
alias migratec=migration_create

function mysql_backup {
	local host="$local_host"
	local user="$local_user"
	local pass="$local_pass"
	local ssh="200"
	local banco=
	local tabelas=
	local exit=false
	local remote=false
	local bIgnoraTabelas=true
	local aTabelasIgnoradas=(log_log uso_usuario usi_usuario_grupo_usuario pro_perfil_usuario usuario_acao sms_sms eml_email)
	local sTabelasIgnoradasComando=''
	
	mkdir -p ~/backups

	while [ "$1" != "" ]; do
		case $1 in
			-h | --host )
				shift
				host=$1
				ssh=
			;;
			-u | --user )
				shift
				user=$1
				ssh=
			;;
			-p | --pass )
				shift
				pass=$1
				ssh=
			;;
			-b | --banco )
				shift
				banco=$1
			;;
			-t | --tabelas )
				shift
				tabelas=$1
			;;
			-f | --full)
				bIgnoraTabelas=false
				;;
			-r | --remote )
				remote=true
				ssh="sindicalizi"
				;;
			--h | -help )
				echo "    Usage: banco [tabela1 tabela2 ...] [-h host] [-u usuario] [-p senha] [-r]"
				echo "       Options:"
				echo "         -h: define o host. 	Padrão: acesso à 200"
				echo "         -u: define o usuario.	Padrão: acesso à 200"
				echo "         -p: define a senha.	Padrão: acesso à 200"
				echo "         -r: troca o padrão de acesso para a produção"
				echo "       Parameters:"
				echo "         -banco: banco que será baixado"
				echo "         -tabelas: tabelas que serão baixadas (opcional)"
				exit=true
			;;
			* )	
				if [[ $banco == "" ]] ; then
					banco=$1
				else 
					if [[ $tabelas == "" ]] ; then
						tabelas="$1"
					else
						tabelas="$tabelas $1"
					fi
				fi
			;;
		esac
		shift
	done

	if [[ $exit == false ]] &&  [[ $banco != "" ]]; then
		if [[ $remote == true ]] ; then
			host="$remote_host"
			user="$remote_user"
			pass="$remote_pass"
			path=remote_"$banco"_$now
		else
			path=local_"$banco"_$now
		fi
		if [[ $tabelas != "" ]] ; then
			path="$path"_"($tabelas)"
		fi
		mkdir -p ~/backups/"$banco"
		path="$path".sql
		fullpath=~/backups/"$banco"/"$path"
		if [[ $bIgnoraTabelas == true ]] ; then
			for tabela in "${aTabelasIgnoradas[@]}"
			do :
			   sTabelasIgnoradasComando+=" --ignore-table=sindical_$banco.${tabela}"
			done
		fi

		if [[ $baixa_por_ssh == true && $remote == true && $ssh != "" ]] ; then
			ssh.exe "$ssh" "mysqldump -u $user -p$pass sindical_$banco $tabelas $sTabelasIgnoradasComando > /tmp/$banco.sql && gzip -f /tmp/$banco.sql"
			scp sindicalizi:/tmp/"$banco".sql.gz ~/backups/temp.gz 
			gunzip -c ~/backups/temp.gz > "$fullpath"
			rm ~/backups/temp.gz 
			sed -i 's/DEFAULT CURRENT_TIMESTAMP//g' "$fullpath"
			sed -i 's/.+DEFINER=.+\n//g' "$fullpath"
		else
			mysqldump -u "$user" -p"$pass" -h "$host" sindical_"$banco" $tabelas $sTabelasIgnoradasComando > "$fullpath" 
			sed -i 's/DEFAULT CURRENT_TIMESTAMP//g' "$fullpath"
			sed -i 's/.+DEFINER=.+\n//g' "$fullpath"
		fi
	fi
}
alias bkp=mysql_backup

function mysql_backup_local {
	echo "Fazendo dump local"
	bkp $@
}
alias bkpl=mysql_backup_local

function mysql_backup_remote {
	if [[ $baixa_por_ssh == true ]]; then
		echo "Fazendo dump de produção por ssh"
	else 
		echo "Fazendo dump de produção"
	fi

	bkp -r $@
}
alias bkpr=mysql_backup_remote

function mysql_upload {
	local host="$local_host"
	local user="$local_user"
	local pass="$local_pass"
	local banco=
	local path=
	local exit=false
	local remote=false
	
	while [ "$1" != "" ]; do
		case $1 in
			-h | --host )
				shift
				host=$1
			;;
			-u | --user )
				shift
				user=$1
			;;
			-p | --pass )
				shift
				pass=$1
			;;
			-b | --banco )
				shift
				banco=$1
			;;
			--h | -help )
				echo "Que doideira!!" 
				exit=true
			;;
			-r | --remote )
				remote=true
				ssh="sindicalizi"
			;;
			-path )
				shift
				path="$*"
			;;
			* )	
				if [[ $banco == "" ]] ; then
					banco=$1
				else 
					if [[ $path == "" ]] ; then
						path="$1"
					fi
				fi
			;;
		esac
		shift
	done

	if [[ $exit == false ]] && [[ $banco != "" ]] && [[ "$path" != "" ]]; then
		if [[ $remote == true ]]; then
			host="$remote_host"
			user="$remote_user"
			pass="$remote_pass"
		fi
		mysql -u "$user" -h "$host" -p"$pass" sindical_"$banco" < "$path"
		[[ $banco == sispag* && $remote == false ]] && mysql_update_urlws_local $banco
		[[ $banco == sispag* && $remote == true ]] && mysql_update_urlws_remote $banco
	fi
}

function mysql_update_urlws_local {
	local banco=${1:-sispag}
	echo "Alterando ema_url_ws de $banco para local" && m "$banco" "update ema_empresa set ema_url_ws = replace(replace(ema_url_ws, '.sindicalizi.com.br',''), 'http://', 'http://localhost/')  where ema_url_ws like '%.sindicalizi.com.br/sispagintegracao/';"
}

function mysql_update_urlws_remote {
	local banco=${1:-sispag}
	echo "Alterando ema_url_ws de $banco para remote" && s "$banco" "update ema_empresa set ema_url_ws = replace(replace(ema_url_ws, 'localhost/', ''), '/sispagintegracao/', '.sindicalizi.com.br/sispagintegracao/') where ema_url_ws like 'http://localhost/%' and ema_url_ws not like 'http://localhost/sispagintegracao/';"
}

alias upl=mysql_upload

function mysql_upload_local {
	echo "Fazendo restore local"
	upl $@
}
alias upll=mysql_upload_local

function mysql_upload_remote {
	
	read -r -p "Tem certeza que deseja subir dados para o servidor? [S/N] " response
	case $response in
		[sS][iI][mM]|[sS])
			echo "Fazendo restore em produção"
			upl -r $@
			;;
		*)
			;;
	esac
}
alias uplr=mysql_upload_remote

function dump {
	bkpr $@ 
	upll $@ -path "$fullpath"
}

function restore {
	bkpl $@ 
	uplr $@ -path "$fullpath"
}

#doc
function help {
	if [[ "$1" != "" ]] ; then
		if [[ -f "$path_profile"/help/"$1" ]]; then
			cat "$path_profile"/help/"$1"
		else
			echo "$1: Ainda não documentada"
		fi
	else
		local funcoes=($(grep "function\ " ~/.bashrc | sed 's/function//' | sed 's/ {//'))
		local falta_documentar=
		for i in "${funcoes[@]}"
		do :
			if [[ -f "$path_profile"/help/"$i" ]]; then
				cat "$path_profile"/help/"$i"
				echo 
			else
				falta_documentar="$falta_documentar\n$i: Ainda não documentada"
			fi
		done

		echo -e "$falta_documentar"
	fi
}

function atalhos {
	# aaAtalhos=$(grep "alias\ .*=[^$].*_" ~/.bashrc | sed 's/alias //')
	# aAtalho="${aaAtalhos	[0]}"
	x=0
	atalhos=()
	grep "alias\ .*=[^$].*_" ~/.bashrc | sed 's/alias //' | while read -r line ; do
		line=(${line//=/ })
		atalhos+=("${line[1]}:${line[0]}")
		# for i in "${atalhos[@]}"
		# do :
		# 	if [[ $i == "$line[1]"* ]]; then
		# 		echo "$i""${line[1]}"
		# 	fi
		# done
	done
	# echo "${atalhos[0,0]} ${atalhos[0,1]}" # will print 0 1
}
