# ------------------------------------
# Gerador Interativo de SealedSecrets
# ------------------------------------
#
# Uso:
#   make secret    - Inicia o assistente interativo para criar um SealedSecret
#   make help      - Exibe ajuda sobre como usar o comando

.PHONY: secret help

# Ajuda para o comando secret
help:
	@echo "📚 Gerador Interativo de SealedSecrets"
	@echo "------------------------------------------------"
	@echo "Uso: make secret"
	@echo ""
	@echo "O comando irá guiá-lo através de um processo interativo para criar um SealedSecret:"
	@echo "  1. Digite o nome do secret (sem o sufixo '-secret', ele será adicionado automaticamente)"
	@echo "  2. Informe os nomes das variáveis de ambiente, separados por espaço"
	@echo "  3. Digite o valor para cada variável (entrada oculta)"
	@echo "  4. Selecione o tipo do secret a partir de uma lista de opções"
	@echo ""
	@echo "O SealedSecret será salvo em k8s/secrets/<nome>-secret.yaml"

# Gera um SealedSecret completamente de forma interativa
secret:
	@# Verifica dependências
	@command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl não encontrado. Instale-o primeiro."; exit 1; }
	@command -v kubeseal >/dev/null 2>&1 || { echo "❌ kubeseal não encontrado. Instale-o primeiro."; exit 1; }
	@echo "🔐 Assistente de Criação de SealedSecrets"
	@echo "------------------------------------------------"
	@# Utilizando shell script para execução contínua e evitar problemas de formatação
	@bash -c '\
		# Solicita o nome do secret \
		printf "👉 Digite o nome do secret (sem o sufixo \"-secret\"): "; \
		read name; \
		if [ -z "$$name" ]; then \
			echo "❌ Nome do secret é obrigatório"; \
			exit 1; \
		fi; \
		secret_name="$$name-secret"; \
		echo "✅ Nome do secret definido: $$secret_name"; \
		\
		# Solicita as variáveis de ambiente \
		printf "👉 Digite os nomes das variáveis separados por espaço (ex: API_KEY DB_PASS): "; \
		read vars; \
		if [ -z "$$vars" ]; then \
			echo "❌ Pelo menos uma variável é obrigatória"; \
			exit 1; \
		fi; \
		echo "✅ Variáveis definidas: $$vars"; \
		\
		# Coleta os valores para cada variável \
		echo "📝 Agora, digite o valor para cada variável:"; \
		temp_args=""; \
		for var in $$vars; do \
			printf "   👉 Digite o valor para $$var (entrada oculta): "; \
			read -r -s value; echo; \
			temp_args="$$temp_args --from-literal=$$var=$$value"; \
		done; \
		echo "✅ Valores coletados para todas as variáveis"; \
		\
		# Apresenta opções de tipo e solicita escolha \
		echo ""; \
		echo "📋 Selecione o tipo do secret:"; \
		echo "   1) Opaque (padrão para a maioria dos secrets)"; \
		echo "   2) kubernetes.io/basic-auth (para autenticação básica)"; \
		echo "   3) kubernetes.io/dockerconfigjson (para registros Docker)"; \
		echo "   4) kubernetes.io/tls (para certificados TLS)"; \
		echo "   5) kubernetes.io/ssh-auth (para autenticação SSH)"; \
		echo "   6) kubernetes.io/service-account-token (para tokens de service account)"; \
		echo "   7) bootstrap.kubernetes.io/token (para tokens de bootstrap)"; \
		echo "   8) Outro (especificar)"; \
		printf "👉 Digite o número da opção desejada [1]: "; \
		read type_option; \
		\
		# Define o tipo com base na escolha \
		case "$$type_option" in \
			""|"1") type="Opaque" ;; \
			"2") type="kubernetes.io/basic-auth" ;; \
			"3") type="kubernetes.io/dockerconfigjson" ;; \
			"4") type="kubernetes.io/tls" ;; \
			"5") type="kubernetes.io/ssh-auth" ;; \
			"6") type="kubernetes.io/service-account-token" ;; \
			"7") type="bootstrap.kubernetes.io/token" ;; \
			"8") \
				printf "👉 Digite o tipo personalizado do secret: "; \
				read custom_type; \
				if [ -z "$$custom_type" ]; then \
					type="Opaque"; \
				else \
					type="$$custom_type"; \
				fi \
				;; \
			*) \
				echo "❌ Opção inválida, usando o tipo padrão"; \
				type="Opaque" \
				;; \
		esac; \
		echo "✅ Tipo do secret definido: $$type"; \
		\
		# Cria o diretório de destino se não existir \
		echo ""; \
		echo "📁 Criando diretório de saída..."; \
		mkdir -p k8s/secrets; \
		\
		# Gera o SealedSecret \
		echo "🛠️  Executando kubectl e kubeseal..."; \
		kubectl create secret generic $$secret_name $$temp_args \
			--type=$$type \
			--dry-run=client -o json | \
		kubeseal \
			--controller-namespace sealed-secrets \
			--controller-name sealed-secrets \
			--format yaml > k8s/secrets/$$secret_name.yaml; \
		\
		echo ""; \
		echo "✅ SealedSecret criado com sucesso!"; \
		echo "📄 Arquivo salvo em: k8s/secrets/$$secret_name.yaml"; \
	'