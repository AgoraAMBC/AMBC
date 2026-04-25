-- ============================================================
-- SEED: Usuário fictício para testes
-- Execute este arquivo no pgAdmin ou em qualquer cliente SQL
-- Banco: ambc
-- ============================================================

DO $$
DECLARE
    v_perfil     INT;
    v_id_usuario INT;
BEGIN

    -- Busca o perfil Administrador
    SELECT id_perfil INTO v_perfil
    FROM perfil_usuario
    WHERE descricao ILIKE 'Administrador'
    LIMIT 1;

    IF v_perfil IS NULL THEN
        RAISE EXCEPTION 'Perfil Administrador não encontrado na tabela perfil_usuario';
    END IF;

    -- Insere o usuário (ignora se e-mail já existir)
    INSERT INTO usuario (nome, email, senha_hash, fk_perfil, ativo, primeiro_acesso)
    VALUES (
        'Fabio Administrador',
        'fabio@ambc.com.br',
        '$2b$10$c7Om7o9G9lb8BnWX.ytHlelkxImVgYXwkmZI6DS1b04k5inLJRHUy',
        v_perfil,
        TRUE,
        FALSE
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id_usuario INTO v_id_usuario;

    IF v_id_usuario IS NULL THEN
        RAISE NOTICE 'Usuário já existia — nenhuma alteração feita.';
        RETURN;
    END IF;

    -- Insere permissões para todos os módulos (acesso + edição completos)
    INSERT INTO permissao_usuario (fk_usuario, fk_modulo, pode_acessar, pode_editar)
    SELECT v_id_usuario, id_modulo, TRUE, TRUE
    FROM modulo_sistema
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Usuário criado com sucesso! ID: %', v_id_usuario;
    RAISE NOTICE 'Email : fabio@ambc.com.br';
    RAISE NOTICE 'Senha : Ambc@2026';

END $$;
