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

--Cửa hàng nên bán nhiều mặt hàng hay tập trung vào bán ít mặt hàng thì bán được nhiều hơn
with aggregate_by_store as ( -- Note: Nên viết dưới dạng CTE để dễ xem, dễ truy ngược và chỉnh sửa query nếu phải sửa lỗi
  select
    store_number,
    upper(store_name) as store_name,
    count(distinct item_number) as number_of_items,
    round(sum(bottles_sold),0) as number_of_bottles_sold,
    -- Note: Bán được nhiều hơn có thể hiểu là bán được số lượng sản phẩm (number_of_bottles_sold) nhiều hơn hoặc bán được nhiều đơn (number_of_orders) hơn.
    count(1) as number_of_orders
  from `bigquery-public-data.iowa_liquor_sales.sales`
  group by 1,2
)

select
  *
  , rank() over (order by number_of_items desc) as rank_number_of_items
  , rank() over (order by number_of_orders desc) as rank_number_of_orders
  , rank() over (order by number_of_bottles_sold desc) as rank_number_of_bottles_sold
  -- Note: Cần có thêm xếp hạng để người xem dễ hình dung mối liên quan về số lượng mặt hàng với số lượng sản phẩm đã bán
from aggregate_by_store
order by 6 asc;
  -- Note: Cuối cùng cần có kết luận của người làm phân tích để người đọc nhanh chóng nắm bắt được ý chính. Trong trường hợp này có thể tạm kết luận là bán nhiều mặt hàng chưa chắc đã đem lại kết quả tốt.


--- Thời gian nào trong năm lượng tiêu thụ bia rượu nhiều nhất
select
  Month,
  round(sum(sale_dollars),0) as sale_dollars_by_month -- Note: Nên hạn chế đổi tên cột để về sau khi chỉnh sửa không mất công truy ngược tên cột
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
        as Day_type,
      -- Note: Các cách khác để viết câu điều kiện
      case
        when extract(dayofweek from date) in (7,1) then "Weekend"
        else "Weekday"
      end as day_type_2,
   
      if(extract(dayofweek from date) in (7,1), "Weekend", "Weekday") as day_type_3
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
      safe_divide(state_bottle_cost,bottle_volume_ml)*1000 as Cost_per_liter -- Note: nên thêm xếp hạng cost_per_liter của mỗi city theo từng sản phẩm để người xem dễ nhìn nhanh ra câu trả lời
  FROM `bigquery-public-data.iowa_liquor_sales.sales`)
order by 4 desc;
