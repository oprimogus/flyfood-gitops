help:
	@echo "📚 Gerador Interativo de SealedSecrets"
	@echo "------------------------------------------------"
	@echo "Uso: make secret"
	@echo ""
	@echo "O comando irá guiá-lo através de um processo interativo para criar um SealedSecret:"
	@echo "  1. Selecione um namespace existente ou digite um novo"
	@echo "  2. Digite o nome do secret (sem o sufixo '-secret')"
	@echo "  3. Informe os nomes das variáveis de ambiente, separados por espaço"
	@echo "  4. Digite o valor para cada variável (entrada oculta)"
	@echo "  5. Selecione o tipo do secret a partir de uma lista de opções"
	@echo ""
	@echo "O SealedSecret será salvo em k8s/secrets/<namespace>-<nome>-secret.yaml"

secret:
	@command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl não encontrado. Instale-o primeiro."; exit 1; }
	@command -v kubeseal >/dev/null 2>&1 || { echo "❌ kubeseal não encontrado. Instale-o primeiro."; exit 1; }
	@echo "🔐 Assistente de Criação de SealedSecrets"
	@echo "------------------------------------------------"
	@bash -c '\
		# Obter lista de namespaces \
		echo "🔍 Buscando namespaces disponíveis..."; \
		namespaces_list=$$( (kubectl get namespaces -o name 2>/dev/null || echo "") | cut -d"/" -f2); \
		if [ -z "$$namespaces_list" ]; then \
			echo "⚠️ Nenhum namespace encontrado. Usando \"default\""; \
			namespace="default"; \
		else \
			echo ""; \
			echo "📋 Selecione o namespace para o secret:"; \
			echo "────────────────────────────────────────────────"; \
			declare -a ns_array; \
			ns_index=1; \
			while IFS= read -r ns; do \
				if [ ! -z "$$ns" ]; then \
					ns_array[$$ns_index]="$$ns"; \
					if [ "$$ns" = "default" ]; then \
						echo -e "  \\e[1;36m[$$ns_index] $$ns\\e[0m"; \
					else \
						echo "  [$$ns_index] $$ns"; \
					fi; \
					ns_index=$$((ns_index+1)); \
				fi; \
			done <<< "$$namespaces_list"; \
			new_option=$$ns_index; \
			echo "  [$$new_option] ➕ Especificar um novo namespace"; \
			echo "────────────────────────────────────────────────"; \
			printf "👉 Selecione o número do namespace [1]: "; \
			read choice; \
			if [ -z "$$choice" ]; then \
				namespace="$${ns_array[1]}"; \
			elif [ "$$choice" = "$$new_option" ]; then \
				printf "👉 Digite o nome do novo namespace: "; \
				read namespace; \
				if [ -z "$$namespace" ]; then \
					namespace="default"; \
					echo "⚠️ Namespace não especificado, usando \"default\""; \
				fi; \
			elif [ "$$choice" -ge 1 ] && [ "$$choice" -lt "$$new_option" ]; then \
				namespace="$${ns_array[$$choice]}"; \
			else \
				echo "⚠️ Opção inválida, usando namespace \"default\""; \
				namespace="default"; \
			fi; \
		fi; \
		echo "✅ Namespace definido: $$namespace"; \
		echo ""; \
		\
		# Nome do secret \
		printf "👉 Digite o nome do secret (sem o sufixo \"-secret\"): "; \
		read name; \
		if [ -z "$$name" ]; then \
			echo "❌ Nome do secret é obrigatório"; \
			exit 1; \
		fi; \
		secret_name="$$name-secret"; \
		output_file="k8s/secrets/$$namespace-$$secret_name.yaml"; \
		echo "✅ Nome do secret definido: $$secret_name"; \
		echo ""; \
		\
		# Variáveis \
		printf "👉 Digite os nomes das variáveis separados por espaço (ex: API_KEY DB_PASS): "; \
		read vars; \
		if [ -z "$$vars" ]; then \
			echo "❌ Pelo menos uma variável é obrigatória"; \
			exit 1; \
		fi; \
		echo "✅ Variáveis definidas: $$vars"; \
		echo "📝 Agora, digite o valor para cada variável:"; \
		temp_args=""; \
		for var in $$vars; do \
			printf "   👉 Digite o valor para $$var (entrada oculta): "; \
			read -r -s value; echo; \
			temp_args="$$temp_args --from-literal=$$var=$$value"; \
		done; \
		echo "✅ Valores coletados para todas as variáveis"; \
		\
		# Tipo do secret \
		echo ""; \
		echo "📋 Selecione o tipo do secret:"; \
		echo "────────────────────────────────────────────────"; \
		echo "  [1] Opaque (padrão para a maioria dos secrets)"; \
		echo "  [2] kubernetes.io/basic-auth (autenticação básica)"; \
		echo "  [3] kubernetes.io/dockerconfigjson (registros Docker)"; \
		echo "  [4] kubernetes.io/tls (certificados TLS)"; \
		echo "  [5] kubernetes.io/ssh-auth (autenticação SSH)"; \
		echo "  [6] kubernetes.io/service-account-token (service account)"; \
		echo "  [7] bootstrap.kubernetes.io/token (tokens de bootstrap)"; \
		echo "  [8] Outro (especificar manualmente)"; \
		echo "────────────────────────────────────────────────"; \
		printf "👉 Digite o número da opção desejada [1]: "; \
		read type_option; \
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
				fi ;; \
			*) \
				echo "❌ Opção inválida, usando o tipo padrão"; \
				type="Opaque" ;; \
		esac; \
		echo "✅ Tipo do secret definido: $$type"; \
		\
		# Geração do secret \
		echo ""; \
		echo "📁 Criando diretório de saída..."; \
		mkdir -p k8s/secrets; \
		echo "🛠️  Executando kubectl e kubeseal..."; \
		kubectl create secret generic $$secret_name $$temp_args \
			--namespace=$$namespace \
			--type=$$type \
			--dry-run=client -o json | \
		kubeseal \
			--controller-namespace sealed-secrets \
			--controller-name sealed-secrets \
			--format yaml > "$$output_file"; \
		echo ""; \
		echo "✅ SealedSecret criado com sucesso!"; \
		echo "📄 Arquivo salvo em: $$output_file"; \
		echo "🔹 Namespace: $$namespace"; \
	'
