.PHONY: secret

secret:
	@if [ -z "$(NAME)" ]; then \
		echo "❌ Defina o nome do secret com NAME=..."; \
		exit 1; \
	fi
	@echo "🔐 Gerando SealedSecret chamado '$(NAME)-secret'..."
	@kubectl create secret generic $(NAME) \
		$(foreach v,$(VARS),--from-literal=$(v)) \
		--dry-run=client -o json | \
	kubeseal \
		--controller-namespace sealed-secrets \
		--controller-name sealed-secrets \
		--format yaml > k8s/secrets/'$(NAME)-secret'.yaml
	@echo "✅ SealedSecret salvo em k8s/secrets/'$(NAME)-secret'.yaml"
