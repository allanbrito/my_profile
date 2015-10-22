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
path_config=.bashconfig
path_profile=~/my_bash
default_params="atualiza_bashrc=true
baixa_por_ssh=false
local_host=192.168.25.200
local_user=root
local_pass=
remote_host=sindicalizi.com.br
remote_user=sindical
remote_pass="

# PS1="\n\[\e[1;30m\][$$:$PPID - \j:\!\[\e[1;30m\]]\[\e[0;36m\] \T \[\e[1;30m\][\[\e[1;34m\]\u@\H\[\e[1;30m\]:\[\e[0;37m\]${SSH_TTY:-o} \[\e[0;32m\]+${SHLVL}\[\e[1;30m\]] \[\e[1;37m\]\w\[\e[0;37m\] \n\$ "

#atalhos
alias ls='ls -F --show-control-chars'
alias gts='git status '
alias e='exit'
alias migrate=migrate_local
alias migrates=migrate_remote
alias migrateo=migrate_especifica
alias migratec=migrate_create
alias bkp=backup
alias bkpl=backup_local
alias bkpr=backup_remote
alias upl=upload
alias upll=upload_local
alias uplr=upl_remote
alias mysql=mysql
alias mysqldump=mysqldump
alias php=php

#exec
# clear
set -o noglob

#iniciar arquivo de configuração
mkdir -p "$path_profile"
( [ -e "$path_config" ] || (touch "$path_config" && echo "$default_params" > "$path_config"))
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
function self_commit {
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
			git pull origin master && 
			git push origin master
			cd "/$path"
		;;
		[vV])
			git diff --no-index -- "$path_profile"/.bashrc "$path_profile"/../.bashrc
			self_commit
		;;
		"")
			self_commit
		;;
	esac 
}

function self_init {
	if [ ! -d "$path_profile"/.git ]; then
		git -C "$path_profile" init 
		git -C "$path_profile" remote add origin https://github.com/allanbrito/my_profile.git 
		git -C "$path_profile" fetch --all
		git -C "$path_profile" pull origin master
		cp "$path_profile"/.bashrc "$path_profile"/../.bashrc
	fi
}

function self_reset {
	if [[ "$windows" == true ]] ; then
		"C:\Program Files (x86)\Git\bin\sh.exe" --login -i
	fi
}
alias reset=self_reset

function self_update {
	git -C "$path_profile" fetch
	if [[ $(git -C "$path_profile" rev-parse HEAD) != $(git -C "$path_profile" rev-parse origin/master) ]]; then
		read -r -p "Deseja atualizar as funções? [S/n] " response
		case $response in
			[sS][iI][mM]|[sS])
				cd "$path_profile"
				git pull origin master
				cp .bashrc ../.bashrc
				self_reset
				
			;;
		esac
	fi	
}

if [[ "$atualiza_bashrc" == true ]] ; then
	self_init 
	if [[ $(diff "$path_profile"/.bashrc "$path_profile"/../.bashrc) ]]; then 
		self_commit
	else 
		self_update
	fi
	clear
fi

function sublime_commit {
	local path="${PWD##/}"
	tar -zcvf "$path_profile"/Sublime_"$whoami".tar -C ~/AppData/Roaming/Sublime\ Text\ 3/Packages/ .
	git -C "$path_profile" add .
	git -C "$path_profile" commit -am "Sublime preferences"
	git -C "$path_profile" pull origin master
	git -C "$path_profile" push
}

function sublime_update {
	local user="$1"
	if [[ "$user" == "" ]] ; then
		user="$whoami"
	fi
	if [[ ! -f "$path_profile"/Sublime_"$user".tar ]]; then
		echo "O sublime de $user não está disponível"
	else
		tar -zxvf  "$path_profile"/Sublime_"$user".tar -C ~/AppData/Roaming/Sublime\ Text\ 3/Packages/
		clear
		echo "Sublime atualizado para o de ${user}!"
	fi
}



#functions
function m {
	local host="$local_host"
	local user="$local_user"
	local pass="$local_pass"
	
	if [[ "$1" == "-r" ]] ; then
		host="$remote_host"
		user="$remote_user"
		pass="$remote_pass"
		shift
	fi

	connection="-u $user -h $host -p$pass"
	if [[ "$2" == "" ]] ; then
		mysql $connection sindical_$1 || mysql $connection
	else
		banco="$1"
		shift
		local sql=$@
		if [[ -f $@ ]]; then
			sql="source ${sql/~/\~}"
		fi
		mysql $connection sindical_$banco -e "$sql" || mysql $connection
	fi
}

function s {
	m -r "$@"
}

function x {
	cd $path_root/"$1"
}

alias gtc="git_commit --"

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

alias gtu=git_update

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

function migration {
	moobidb --no-ansi "$@"
}

function migrate_local {
	migration --migrate --all "$@"
}

function migrate_remote {
	migration --migrate --prod --all "$@"
}

function migrate_especifica {
	migration --all --run "$@"
}

function migrate_create {
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

function backup {
	local host="$local_host"
	local user="$local_user"
	local pass="$local_pass"
	local ssh="200"
	local banco=
	local tabelas=
	local exit=false
	local remote=false
	
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
		if [[ $baixa_por_ssh == true && $remote == true && $ssh != "" ]] ; then
			ssh.exe "$ssh" "mysqldump -u $user -p$pass sindical_$banco $tabelas --ignore-table=sindical_$banco.log_log > /tmp/$banco.sql && gzip -f /tmp/$banco.sql"
			scp sindicalizi:/tmp/"$banco".sql.gz ~/backups/temp.gz 
			gunzip -c ~/backups/temp.gz > "$fullpath"
			rm ~/backups/temp.gz 
			sed -i 's/DEFAULT CURRENT_TIMESTAMP//g' "$fullpath"
		else
			mysqldump -u "$user" -p"$pass" -h "$host" sindical_"$banco" $tabelas --ignore-table=sindical_"$banco".log_log > "$fullpath" 
			sed -i 's/DEFAULT CURRENT_TIMESTAMP//g' "$fullpath"
		fi
	fi
}

function backup_local {
	echo "Fazendo dump local"
	bkp $@
}

function backup_remote {
	if [[ $baixa_por_ssh == true ]]; then
		echo "Fazendo dump de produção por ssh"
	else 
		echo "Fazendo dump de produção"
	fi

	bkp -r $@
}

function upload {
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
		[[ $banco == sispag* && $remote == false ]] && echo "Alterando ema_url_ws para local" && m "$banco" "update ema_empresa set ema_url_ws = replace(replace(ema_url_ws, '.sindicalizi.com.br',''), 'http://', 'http://localhost/')  where ema_url_ws like '%.sindicalizi.com.br/sispagintegracao/';"
		[[ $banco == sispag* && $remote == true ]] && echo "Alterando ema_url_ws para remote" && m "$banco" "update ema_empresa set ema_url_ws = replace(replace(ema_url_ws, 'localhost/', ''), '/sispagintegracao/', '.sindicalizi.com.br/sispagintegracao/') where ema_url_ws like 'http://localhost/%' and ema_url_ws not like 'http://localhost/sispagintegracao/';"
	fi
}

function upload_local {
	echo "Fazendo restore local"
	upl $@
}

function upl_remote {
	
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
	echo "    migrate: migrate_local"
	echo "    migrates: migrate_remote"
	echo "    migrateo: migrate_especifica"
	echo "    migratec: migrate_create"
	echo "    bkpl: backup_local"
	echo "    bkpr: backup_remote"
	echo "    upll: upload_local"
	echo "    uplr: upl_remote"
	echo "    gts: git status"
	echo "    e: exit"
}
