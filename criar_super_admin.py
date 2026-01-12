import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Inicializar Firebase Admin SDK
cred = credentials.Certificate(r'C:\scripts\funcionarios\serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

def criar_super_admin():
    try:
        # Criar documento do super admin
        super_admin_ref = db.collection('comissao').document('03308')

        super_admin_ref.set({
            'matricula': '03308',
            'senha': '1234',  # Senha padrão - pode ser alterada depois
            'ativo': True,
            'isSuperAdmin': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
        })

        print('Super Admin criado com sucesso!')
        print('Matricula: 03308')
        print('Senha: 1234')
        print('')
        print('IMPORTANTE: Altere a senha apos o primeiro login usando a tela de gerenciamento!')

    except Exception as e:
        print(f'Erro ao criar super admin: {e}')
        return False

    return True

if __name__ == '__main__':
    criar_super_admin()
