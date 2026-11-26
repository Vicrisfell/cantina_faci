-- CPF do responsável (login por CPF usa o e-mail interno {cpf}@cpf.cantinafacil.app)
alter table public.cantina_profiles
  add column if not exists cpf text unique
  check (cpf is null or cpf ~ '^[0-9]{11}$');

-- Função auxiliar: o usuário logado é responsável pelo aluno?
-- SECURITY DEFINER evita recursão de RLS ao consultar responsavel_aluno.
create or replace function public.is_responsavel_de_aluno(p_aluno uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.responsavel_aluno ra
    where ra.id_aluno = p_aluno
      and ra.id_usuario_responsavel = (select auth.uid())
  );
$$;

revoke execute on function public.is_responsavel_de_aluno(uuid) from public, anon;
grant execute on function public.is_responsavel_de_aluno(uuid) to authenticated;

-- responsavel_aluno
alter table public.responsavel_aluno enable row level security;
grant select on public.responsavel_aluno to authenticated;
drop policy if exists "responsavel ve seus vinculos" on public.responsavel_aluno;
create policy "responsavel ve seus vinculos" on public.responsavel_aluno
  for select to authenticated
  using (id_usuario_responsavel = (select auth.uid()));

-- aluno
alter table public.aluno enable row level security;
grant select on public.aluno to authenticated;
drop policy if exists "responsavel ve seus alunos" on public.aluno;
create policy "responsavel ve seus alunos" on public.aluno
  for select to authenticated
  using (public.is_responsavel_de_aluno(id_aluno));

-- aluno_unidade
alter table public.aluno_unidade enable row level security;
grant select on public.aluno_unidade to authenticated;
drop policy if exists "responsavel ve vinculo aluno-unidade" on public.aluno_unidade;
create policy "responsavel ve vinculo aluno-unidade" on public.aluno_unidade
  for select to authenticated
  using (public.is_responsavel_de_aluno(id_aluno));

-- unidade
alter table public.unidade enable row level security;
grant select on public.unidade to authenticated;
drop policy if exists "responsavel ve unidades dos filhos" on public.unidade;
create policy "responsavel ve unidades dos filhos" on public.unidade
  for select to authenticated
  using (exists (
    select 1 from public.aluno_unidade au
    where au.id_unid = unidade.id_unidade
      and public.is_responsavel_de_aluno(au.id_aluno)
  ));

-- carteira
alter table public.carteira enable row level security;
grant select on public.carteira to authenticated;
drop policy if exists "responsavel ve carteira dos filhos" on public.carteira;
create policy "responsavel ve carteira dos filhos" on public.carteira
  for select to authenticated
  using (public.is_responsavel_de_aluno(id_aluno));

-- movimentacao_carteira
alter table public.movimentacao_carteira enable row level security;
grant select on public.movimentacao_carteira to authenticated;
drop policy if exists "responsavel ve movimentacoes dos filhos" on public.movimentacao_carteira;
create policy "responsavel ve movimentacoes dos filhos" on public.movimentacao_carteira
  for select to authenticated
  using (exists (
    select 1 from public.carteira c
    where c.id_carteira = movimentacao_carteira.id_carteira
      and public.is_responsavel_de_aluno(c.id_aluno)
  ));

-- venda
alter table public.venda enable row level security;
grant select on public.venda to authenticated;
drop policy if exists "responsavel ve vendas dos filhos" on public.venda;
create policy "responsavel ve vendas dos filhos" on public.venda
  for select to authenticated
  using (public.is_responsavel_de_aluno(id_aluno));

-- itens_venda
alter table public.itens_venda enable row level security;
grant select on public.itens_venda to authenticated;
drop policy if exists "responsavel ve itens das vendas dos filhos" on public.itens_venda;
create policy "responsavel ve itens das vendas dos filhos" on public.itens_venda
  for select to authenticated
  using (exists (
    select 1 from public.venda v
    where v.id_venda = itens_venda.id_venda
      and public.is_responsavel_de_aluno(v.id_aluno)
  ));

-- produto
alter table public.produto enable row level security;
grant select on public.produto to authenticated;
drop policy if exists "responsavel ve produtos comprados" on public.produto;
create policy "responsavel ve produtos comprados" on public.produto
  for select to authenticated
  using (exists (
    select 1 from public.itens_venda iv
    join public.venda v on v.id_venda = iv.id_venda
    where iv.id_produto = produto.id
      and public.is_responsavel_de_aluno(v.id_aluno)
  ));

-- membros_organizacao (dados de contato/endereço do próprio responsável)
alter table public.membros_organizacao enable row level security;
grant select on public.membros_organizacao to authenticated;
drop policy if exists "responsavel ve seus dados de contato" on public.membros_organizacao;
create policy "responsavel ve seus dados de contato" on public.membros_organizacao
  for select to authenticated
  using (id_usuario = (select auth.uid()));
