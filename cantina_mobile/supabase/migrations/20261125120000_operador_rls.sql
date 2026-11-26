-- Operador/gestor: enxerga somente as unidades em que está ativo em membro_unidade.

create or replace function public.is_membro_unidade(p_unid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.membro_unidade mu
    where mu.id_unid = p_unid
      and mu.id_usuario = (select auth.uid())
      and mu.ativo = true
  );
$$;

revoke execute on function public.is_membro_unidade(uuid) from public, anon;
grant execute on function public.is_membro_unidade(uuid) to authenticated;

-- membro_unidade
alter table public.membro_unidade enable row level security;
grant select on public.membro_unidade to authenticated;
drop policy if exists "membro ve seus vinculos" on public.membro_unidade;
create policy "membro ve seus vinculos" on public.membro_unidade
  for select to authenticated
  using (id_usuario = (select auth.uid()));

-- unidade
alter table public.unidade enable row level security;
grant select on public.unidade to authenticated;
drop policy if exists "operador ve suas unidades" on public.unidade;
create policy "operador ve suas unidades" on public.unidade
  for select to authenticated
  using (public.is_membro_unidade(id_unidade));

-- aluno_unidade
alter table public.aluno_unidade enable row level security;
grant select on public.aluno_unidade to authenticated;
drop policy if exists "operador ve alunos da unidade" on public.aluno_unidade;
create policy "operador ve alunos da unidade" on public.aluno_unidade
  for select to authenticated
  using (public.is_membro_unidade(id_unid));

-- aluno
alter table public.aluno enable row level security;
grant select on public.aluno to authenticated;
drop policy if exists "operador ve alunos da sua unidade" on public.aluno;
create policy "operador ve alunos da sua unidade" on public.aluno
  for select to authenticated
  using (exists (
    select 1 from public.aluno_unidade au
    where au.id_aluno = aluno.id_aluno
      and public.is_membro_unidade(au.id_unid)
  ));

-- carteira
alter table public.carteira enable row level security;
grant select on public.carteira to authenticated;
drop policy if exists "operador ve carteiras da unidade" on public.carteira;
create policy "operador ve carteiras da unidade" on public.carteira
  for select to authenticated
  using (public.is_membro_unidade(id_unid));

-- produto
alter table public.produto enable row level security;
grant select on public.produto to authenticated;
drop policy if exists "operador ve produtos da unidade" on public.produto;
create policy "operador ve produtos da unidade" on public.produto
  for select to authenticated
  using (public.is_membro_unidade(id_unidade));

-- estoque (leitura e ajuste pelo operador)
alter table public.estoque enable row level security;
grant select, update on public.estoque to authenticated;
drop policy if exists "operador ve estoque da unidade" on public.estoque;
create policy "operador ve estoque da unidade" on public.estoque
  for select to authenticated
  using (public.is_membro_unidade(id_unidade));
drop policy if exists "operador ajusta estoque da unidade" on public.estoque;
create policy "operador ajusta estoque da unidade" on public.estoque
  for update to authenticated
  using (public.is_membro_unidade(id_unidade))
  with check (public.is_membro_unidade(id_unidade));

-- venda
alter table public.venda enable row level security;
grant select on public.venda to authenticated;
drop policy if exists "operador ve vendas da unidade" on public.venda;
create policy "operador ve vendas da unidade" on public.venda
  for select to authenticated
  using (public.is_membro_unidade(id_unid));

-- itens_venda
alter table public.itens_venda enable row level security;
grant select on public.itens_venda to authenticated;
drop policy if exists "operador ve itens da unidade" on public.itens_venda;
create policy "operador ve itens da unidade" on public.itens_venda
  for select to authenticated
  using (public.is_membro_unidade(id_unid));

-- pagamento_venda
alter table public.pagamento_venda enable row level security;
grant select on public.pagamento_venda to authenticated;
drop policy if exists "operador ve pagamentos da unidade" on public.pagamento_venda;
create policy "operador ve pagamentos da unidade" on public.pagamento_venda
  for select to authenticated
  using (public.is_membro_unidade(id_unid));
