<?php
$pdo = new PDO('pgsql:host=localhost;port=5432;dbname=AMBC', 'postgres', 'Leo@naruto0909');
$rows = $pdo->query('SELECT nome, email FROM usuario')->fetchAll(PDO::FETCH_ASSOC);
foreach ($rows as $r) echo $r['nome'] . ' — ' . $r['email'] . PHP_EOL;
