-- RASCUNHO: revise antes de aplicar. Os nomes de colunas seguem a especificação,
-- mas `criado_por` e o tipo de `auth.uid()` precisam ser conferidos no seu schema.
create or replace function public.estornar_venda(p_id_venda uuid)
returns void
language plpgsql
security invoker
as $$
declare
  v        record;
  v_carteira uuid;
begin
  select * into v from public.venda where id_venda = p_id_venda for update;
  if not found then
    raise exception 'Venda não encontrada';
  end if;
  if v.status <> 'paid' then
    raise exception 'Somente vendas pagas podem ser estornadas (status atual: %)', v.status;
  end if;

  update public.venda set status = 'refunded' where id_venda = p_id_venda;

  -- Devolve o valor à carteira do aluno, quando a venda tem aluno.
  if v.id_aluno is not null then
    select id_carteira into v_carteira
      from public.carteira
     where id_aluno = v.id_aluno and id_unid = v.id_unid
     for update;

    if v_carteira is not null then
      update public.carteira set saldo = saldo + v.total where id_carteira = v_carteira;
      insert into public.movimentacao_carteira
        (id_carteira, id_unid, id_venda, tipo, valor, criado_por)
      values
        (v_carteira, v.id_unid, p_id_venda, 'refund', v.total, auth.uid());
    end if;
  end if;

  -- Devolve as quantidades ao estoque.
  update public.estoque e
     set quantidade = e.quantidade + i.qtd
    from (
      select id_produto, sum(quantidade) as qtd
        from public.itens_venda
       where id_venda = p_id_venda
       group by id_produto
    ) i
   where e.id_produto = i.id_produto
     and e.id_unidade = v.id_unid;
end;
$$;
