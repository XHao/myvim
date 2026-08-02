.PHONY: install submodules vimrc plugins tern help update verify

INSTALL_DIR := scripts/install.d

install: submodules vimrc plugins tern help verify
	@echo ""
	@echo "== 安装完成。上方如有 WARN 请按提示处理 =="

submodules:
	bash $(INSTALL_DIR)/10-submodules.sh

vimrc:
	bash $(INSTALL_DIR)/20-vimrc.sh

plugins:
	bash $(INSTALL_DIR)/30-plugins.sh

tern:
	bash $(INSTALL_DIR)/40-tern.sh

help:
	vim -E -s -c "helptags $(HOME)/.vim/doc" -c "qa" </dev/null
	@echo "[ OK ] doc/tags 已生成"

update:
	git submodule update --init
	vim -E -s -c 'source $$HOME/.vimrc' -c "PluginInstall!" -c "qa" </dev/null

verify:
	bash scripts/verify.sh
	vim -E -s -S scripts/verify.vim </dev/null
