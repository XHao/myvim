.PHONY: install submodules vimrc plugins help update verify preflight deps coding

INSTALL_DIR := scripts/install.d

install: verify
	@echo ""
	@echo "== 安装完成。上方如有 WARN 请按提示处理 =="

preflight:
	bash $(INSTALL_DIR)/00-preflight.sh

deps: preflight
	bash $(INSTALL_DIR)/05-deps.sh

submodules: deps
	bash $(INSTALL_DIR)/10-submodules.sh

vimrc: submodules
	bash $(INSTALL_DIR)/20-vimrc.sh

plugins: vimrc
	bash $(INSTALL_DIR)/30-plugins.sh

help: plugins
	vim -E -s -c 'helptags $$HOME/.vim/doc' -c "qa" </dev/null
	@echo "[ OK ] doc/tags 已生成"

update:
	git submodule update --init
	vim -E -s -c 'source $$HOME/.vimrc' -c "PlugUpdate --sync" -c "qa" </dev/null

verify: help
	bash scripts/verify.sh
	vim -E -s -S scripts/verify.vim </dev/null

coding: plugins
	bash $(INSTALL_DIR)/60-coding.sh
