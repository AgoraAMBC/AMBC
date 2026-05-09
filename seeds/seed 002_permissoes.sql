INSERT INTO permissao_usuario (fk_usuario, fk_modulo, pode_acessar, pode_editar)
SELECT
    u.id_usuario,
    m.id_modulo,
    TRUE,
    TRUE
FROM usuario u
CROSS JOIN modulo_sistema m
WHERE u.email IN (
    'adrianeb.reis22@gmail.com',
    'bonicrattay@gmail.com',
    'cristesta.rp@gmail.com',
    'fabiomachado1212@gmail.com',
    'leonardo.leote0909@gmail.com',
    'mikaelatsk@gmail.com'
);