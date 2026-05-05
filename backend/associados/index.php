<?php
/**
 * ============================================================
 * ENDPOINT: /backend/associados
 * ============================================================
 * Gerencia CRUD de associados
 * 
 * POST   /backend/associados            → Criar novo associado
 * GET    /backend/associados/{id}       → Buscar associado
 * GET    /backend/associados            → Listar todos (com filtros)
 * PUT    /backend/associados/{id}       → Atualizar associado
 * DELETE /backend/associados/{id}       → Excluir associado
 * ============================================================
 */

declare(strict_types=1);
require_once dirname(__DIR__) . '/config/database.php';
require_once dirname(__DIR__) . '/helpers.php';

// 🌐 CORS
configurarCors();

// ─────────────────────────────────────────────────
// Rotear requisições HTTP
// ─────────────────────────────────────────────────

$metodo = $_SERVER['REQUEST_METHOD'];
$corpo = ($metodo === 'POST' || $metodo === 'PUT') ? corpoJson() : [];

// Extrai o ID da URL (se existir)
$pathInfo = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$parts = array_filter(explode('/', $pathInfo));
$id = end($parts) && is_numeric(end($parts)) ? (int)end($parts) : null;

$pdo = obterConexao();

switch ($metodo) {
    // ─────────────────────────────────────────────────
    // GET - Buscar associado(s)
    // ─────────────────────────────────────────────────
    case 'GET':
        if ($id) {
            // GET /backend/associados/{id}
            buscarPorId($pdo, $id);
        } else {
            // GET /backend/associados (com filtros opcionais)
            listarTodos($pdo);
        }
        break;

    // ─────────────────────────────────────────────────
    // POST - Criar novo associado
    // ─────────────────────────────────────────────────
    case 'POST':
        criar($pdo, $corpo);
        break;

    // ─────────────────────────────────────────────────
    // PUT - Atualizar associado
    // ─────────────────────────────────────────────────
    case 'PUT':
        if (!$id) {
            jsonErro('ID do associado é obrigatório para atualizar', 400);
        }
        atualizar($pdo, $id, $corpo);
        break;

    // ─────────────────────────────────────────────────
    // DELETE - Excluir associado
    // ─────────────────────────────────────────────────
    case 'DELETE':
        if (!$id) {
            jsonErro('ID do associado é obrigatório para excluir', 400);
        }
        excluir($pdo, $id);
        break;

    default:
        jsonErro('Método HTTP não permitido', 405);
}

// ─────────────────────────────────────────────────
// FUNÇÕES DE NEGÓCIO
// ─────────────────────────────────────────────────

function listarTodos(PDO $pdo): void
{
    $stmt = $pdo->query('
        SELECT 
            id_associado, 
            matricula, 
            nome, 
            cpf, 
            email, 
            fk_status,
            data_cadastro,
            ativo
        FROM associado
        ORDER BY data_cadastro DESC
        LIMIT 1000
    ');
    $associados = $stmt->fetchAll();
    jsonResposta(['data' => $associados]);
}

function buscarPorId(PDO $pdo, int $id): void
{
    $stmt = $pdo->prepare('
        SELECT * FROM associado WHERE id_associado = :id
    ');
    $stmt->execute([':id' => $id]);
    $associado = $stmt->fetch();

    if (!$associado) {
        jsonErro('Associado não encontrado', 404);
    }

    jsonResposta(['data' => $associado]);
}

function criar(PDO $pdo, array $dados): void
{
    // Validação básica
    if (empty($dados['nome']) || empty($dados['cpf']) || !isset($dados['fk_status'])) {
        jsonErro('Nome, CPF e Status são obrigatórios', 400);
    }

    // Gerar matrícula única
    $matricula = gerarMatricula($pdo);

    // Preparar dados
    $stmt = $pdo->prepare('
        INSERT INTO associado (
            matricula,
            nome,
            cpf,
            fk_status,
            data_nascimento,
            fk_genero,
            fk_estado_civil,
            fk_profissao,
            data_entrada,
            email,
            observacao,
            cep,
            logradouro,
            numero,
            complemento,
            bairro,
            cidade,
            uf,
            data_cadastro,
            ativo
        ) VALUES (
            :matricula,
            :nome,
            :cpf,
            :fk_status,
            :data_nascimento,
            :fk_genero,
            :fk_estado_civil,
            :fk_profissao,
            :data_entrada,
            :email,
            :observacao,
            :cep,
            :logradouro,
            :numero,
            :complemento,
            :bairro,
            :cidade,
            :uf,
            NOW(),
            TRUE
        )
        RETURNING id_associado, matricula, nome, email
    ');

    try {
        $stmt->execute([
            ':matricula'          => $matricula,
            ':nome'               => $dados['nome'] ?? null,
            ':cpf'                => $dados['cpf'] ?? null,
            ':fk_status'          => $dados['fk_status'] ?? null,
            ':data_nascimento'    => $dados['dataNascimento'] ?? null,
            ':fk_genero'          => $dados['fkGenero'] ?? null,
            ':fk_estado_civil'    => $dados['fkEstadoCivil'] ?? null,
            ':fk_profissao'       => $dados['fkProfissao'] ?? null,
            ':data_entrada'       => $dados['dataEntrada'] ?? null,
            ':email'              => $dados['email'] ?? null,
            ':observacao'         => $dados['observacao'] ?? null,
            ':cep'                => $dados['cep'] ?? null,
            ':logradouro'         => $dados['logradouro'] ?? null,
            ':numero'             => $dados['numero'] ?? null,
            ':complemento'        => $dados['complemento'] ?? null,
            ':bairro'             => $dados['bairro'] ?? null,
            ':cidade'             => $dados['cidade'] ?? null,
            ':uf'                 => $dados['uf'] ?? null,
        ]);

        $associado = $stmt->fetch();
        jsonResposta(['data' => $associado], 201);
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'duplicate') !== false || strpos($e->getMessage(), 'UNIQUE') !== false) {
            jsonErro('CPF já cadastrado para outro associado', 409);
        }
        throw $e;
    }
}

function atualizar(PDO $pdo, int $id, array $dados): void
{
    // Verificar se associado existe
    $stmt = $pdo->prepare('SELECT id_associado FROM associado WHERE id_associado = :id');
    $stmt->execute([':id' => $id]);
    if (!$stmt->fetch()) {
        jsonErro('Associado não encontrado', 404);
    }

    $campos = [];
    $params = [':id' => $id];

    // Monta a clausula SET dinamicamente
    $mapeoCampos = [
        'nome'              => 'nome',
        'fkStatus'          => 'fk_status',
        'dataNascimento'    => 'data_nascimento',
        'fkGenero'          => 'fk_genero',
        'fkEstadoCivil'     => 'fk_estado_civil',
        'fkProfissao'       => 'fk_profissao',
        'dataEntrada'       => 'data_entrada',
        'email'             => 'email',
        'observacao'        => 'observacao',
        'cep'               => 'cep',
        'logradouro'        => 'logradouro',
        'numero'            => 'numero',
        'complemento'       => 'complemento',
        'bairro'            => 'bairro',
        'cidade'            => 'cidade',
        'uf'                => 'uf',
    ];

    foreach ($mapeoCampos as $chaveJson => $colunaBd) {
        if (isset($dados[$chaveJson])) {
            $campos[] = "$colunaBd = :$chaveJson";
            $params[":$chaveJson"] = $dados[$chaveJson];
        }
    }

    if (empty($campos)) {
        jsonErro('Nenhum campo para atualizar', 400);
    }

    $sql = 'UPDATE associado SET ' . implode(', ', $campos) . ' WHERE id_associado = :id RETURNING id_associado, matricula, nome';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $associado = $stmt->fetch();

    jsonResposta(['data' => $associado]);
}

function excluir(PDO $pdo, int $id): void
{
    $stmt = $pdo->prepare('DELETE FROM associado WHERE id_associado = :id');
    $stmt->execute([':id' => $id]);

    if ($stmt->rowCount() === 0) {
        jsonErro('Associado não encontrado', 404);
    }

    jsonResposta(['mensagem' => 'Associado excluído com sucesso']);
}

function gerarMatricula(PDO $pdo): string
{
    $ano = date('Y');
    
    // Busca o maior número de matrícula do ano
    $stmt = $pdo->prepare('
        SELECT MAX(CAST(SUBSTRING(matricula, 9) AS INTEGER)) as numero
        FROM associado
        WHERE matricula LIKE :ano
    ');
    $stmt->execute([':ano' => "ASS-$ano-%"]);
    $resultado = $stmt->fetch();
    
    $numero = ($resultado['numero'] ?? 0) + 1;
    return sprintf('ASS-%d-%04d', $ano, $numero);
}

?>
