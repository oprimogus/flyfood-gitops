.PHONY: secret

secret:
	@if [ -z "$(NAME)" ]; then \
		echo "❌ Defina o nome do secret com NAME=..."; \
		exit 1; \
	fi; \
	if [ -z "$(VARS)" ]; then \
		echo "❌ Defina as variáveis com VARS='KEY1 KEY2'"; \
		exit 1; \
	fi; \
	echo "🔐 Gerando SealedSecret interativamente..."; \
	temp_args=""; \
	for var in $(VARS); do \
		printf "Digite o valor de $$var: "; \
		read -s value; echo; \
		temp_args="$$temp_args --from-literal=$$var=$$value"; \
	done; \
	kubectl create secret generic $(NAME)-secret $$temp_args \
		--dry-run=client -o json | \
	kubeseal \
		--controller-namespace sealed-secrets \
		--controller-name sealed-secrets \
		--format yaml > k8s/secrets/$(NAME)-secret.yaml; \
	echo "✅ SealedSecret salvo em k8s/secrets/$(NAME)-secret.yaml"
