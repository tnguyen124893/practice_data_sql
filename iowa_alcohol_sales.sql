--Nên bán một pack bao nhiêu chai thì bán được nhiều nhất?
select
    item_number,
    Label,  
    pack,
    bottle_volume_ml,
    Sold_bottles,
    Ranking
from
  (SELECT
    item_number,
    upper(item_description) as Label,  
    pack,
    bottle_volume_ml,
    sum(bottles_sold) as Sold_bottles,
    rank() over(partition by item_number order by sum(bottles_sold) desc) as Ranking
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  group by 1,2,3,4
  order by 1 asc, sum(bottles_sold) desc)
where Ranking=1;

--Cửa hàng nênbán nhiều mặt hàng hay tập trung vào bán ít mặt hàng thì bán được nhiều hơn
select
  store_number,
  upper(store_name) as Store,
  count(distinct item_number) as No_items,
  round(sum(sale_dollars),0) as Sales,
  round(sum(sale_dollars)/count(distinct item_number),0) as SalesPerItems
FROM `bigquery-public-data.iowa_liquor_sales.sales`
group by 1,2
order by 5 desc;

--- Thời gian nào trong năm lượng tiêu thụ bia rượu nhiều nhất
select
  Month,
  round(sum(sale_dollars),0) as Sale_By_Month
from
  (select
    extract(month from date) as Month,
    sale_dollars
  FROM `bigquery-public-data.iowa_liquor_sales.sales`)
group by 1
order by 2 desc;

---Trong tuần và cuối tuần có khác biệt gì không?
select
  Day_type,
  round(sum(sale_dollars),0) as Sales
from
  (Select
      extract(dayofweek from date),
      sale_dollars,
      Case extract(dayofweek from date)
        when 7 then 'Weekend'
        when 1 then 'Weekend'
        else 'Weekday'
        end
        as Day_type
  FROM `bigquery-public-data.iowa_liquor_sales.sales`)
group by 1;

---Nên bán ở đâu thì có lợi nhuận cao nhất?
select
  upper(city) as City,
  round(sum(sale_dollars)-sum(state_bottle_cost*bottles_sold),0) as Revenue
from `bigquery-public-data.iowa_liquor_sales.sales`
group by 1
order by 2 desc;

---Ở đâu có giá mua vào cao nhất?
select
  item_number,
  Label,
  City,
  Cost_per_liter,
  state_bottle_cost,
  bottle_volume_ml,
from
  (SELECT
      item_number,
      upper(item_description) as Label,
      upper(city) as City,
      state_bottle_cost,
      bottle_volume_ml,
      safe_divide(state_bottle_cost,bottle_volume_ml)*1000 as Cost_per_liter
  FROM `bigquery-public-data.iowa_liquor_sales.sales`)
order by 4 desc;
