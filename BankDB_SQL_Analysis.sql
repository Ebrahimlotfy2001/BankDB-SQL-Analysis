use BankDB ;
---------------------------------------------------
BANK DATA ANALYSIS PROJECT
Database : Czech Bank
Author   : Ebrahim
Description:
SQL analysis project using joins, CTEs,
window functions, aggregations and business metrics.
---------------------------------------------------
-- 01. DATA EXPLORATION
-------------------------
-- Q1: Total Number of Clients
select count(*) as Total_clients
from [dbo].[client] ;
--------------------------------
-- Q2: Total Number of Accounts
 select count(*) as Total_accounts
 from [dbo].[account] ;
 ------------------------------
 -- Q3: Total Number of Loans
 select count(*) as Total_loan
 from [dbo].[loan] ;
 -----------------------------
 -- Q4: Count Total Transactions
 select count(*) as Total_trans
 from [dbo].[trans] ;
 -------------------------------------------------------
-- 02. BUSINESS QUESTIONS
-------------------------------------------------------
-- Q5: Number of Clients by District
select d.district_name , count(c.client_id) as Total_clients
from [dbo].[client] c
join [dbo].[district] d on c.district_id = d.district_id
group by d.district_name
order by Total_clients desc ;
-------------------------------------------------------
-- Q6: Number of Accounts by District
select d.district_name , count(a.account_id) as Total_accounts
from [dbo].[district] d
join [dbo].[account] a on a.district_id = d.district_id
group by d.district_name
order by Total_accounts desc ;
-------------------------------------------------------
-- Q7: Total Loan Amount by District
select d.district_name , sum(amount) as Total_amount
from [dbo].[district] d
join [dbo].[account] a on d.district_id = a.district_id
join [dbo].[loan] l on l.account_id = a.account_id
group by d.district_name
order by Total_amount desc ;
-------------------------------------------------------
-- Q8: Loans Ordered by Amount
select d.district_name , l.date , l.amount
from [dbo].[district] d
join [dbo].[account] a on d.district_id = a.district_id
join [dbo].[loan] l on a.account_id = l.account_id
order by l.amount desc ; 
-------------------------------------------------------
-- Q9: Top 10 Clients by Total Loan Amount
select Top (10)
c.client_id ,
d.district_name ,
sum(l.amount) as Total_Loan_Amount
from [dbo].[client] c
join [dbo].[district] d on c.district_id = d.district_id
join [dbo].[disp] di on di.client_id = c.client_id
join [dbo].[account] a on a.account_id = di.account_id
join [dbo].[loan] l on l.account_id = a.account_id
group by c.client_id ,d.district_name
order by Total_Loan_Amount desc ;
-------------------------------------------------------
-- Q10: Clients Without Loans
select Top (10)
c.client_id ,
d.district_name 
from [dbo].[client] c
join [dbo].[district] d on c.district_id = d.district_id
join [dbo].[disp] di on di.client_id = c.client_id
join [dbo].[account] a on a.account_id = di.account_id
left join [dbo].[loan] l on l.account_id = a.account_id
where l.loan_id is null ;
-------------------------------------------------------
-- 03. COMMON TABLE EXPRESSIONS (CTEs)
-------------------------------------------------------
With AverageLoanPerAccount as 
( select a.account_id , Avg(l.amount) as Average_Loan_Amount 
from account a
join loan l on a.account_id = l.account_id
group by a.account_id )
select *
from AverageLoanPerAccount 
where Average_Loan_Amount > 200000 ;

WITH DistrictLoanSummary as
(select d.district_name , sum(l.amount) as Total_Loan_Amount
from district d
join account a on d.district_id = a.district_id
join loan l on a.account_id = l.account_id
group by d.district_name )
select *
from DistrictLoanSummary
where Total_Loan_Amount > 1000000 ;
-------------------------------------------------------
-- 04. WINDOW FUNCTIONS
-------------------------------------------------------
-- Q11: Rank Loans by Amount
select loan_id , amount ,
rank() over (order by amount desc) as Loan_Rank
from loan ;

-- Q12: Dense Rank Loans by Amount
select loan_id , amount ,
DENSE_RANK () over (order by amount desc ) as Loan_Dense_Rank 
from loan ;

-- Q13: Row Number of Loans Within Each District
select d.district_name , amount ,
Row_number () over (partition by d.district_name order by amount desc ) as Loan_Row_Number 
from loan l
join account a on a.account_id = l.account_id
join district d on d.district_id = a.district_id ;

-- Q14: Compare Loan Amount with Previous Loan
select loan_id , date , amount , 
lag (amount) over (order by date ) as Previous_Amount ,
amount - LAG(amount) OVER (ORDER BY date) AS Difference
from loan ;

-- Q15: Compare Loan Amount with Next Loan
select loan_id , date , amount , 
lead (amount) over (order by date ) as Next_amount ,
amount - lead (amount) over (order by date ) as Difference
from loan ;
-------------------------------------------------------
-- 05. BUSINESS METRICS
-------------------------------------------------------
-- Q16: District Summary
with DistrictSummary as 
(select d.district_name , count(Distinct a.account_id) as Total_accounts , 
count(l.loan_id) as Total_loan , sum(l.amount) as Total_amount
from [dbo].[district] d
join account a on d.district_id = a.district_id
join loan l on l.account_id = a.account_id
group by d.district_name )
select *
from DistrictSummary ;

-- Q17: Percentage of Accounts with Loans
WITH TotalAccounts AS
(SELECT COUNT(*) AS Total_Accounts
  FROM account),
LoanAccounts AS
(SELECT COUNT(DISTINCT account_id) AS Accounts_With_Loan
 FROM loan)
SELECT t.Total_Accounts, l.Accounts_With_Loan,
    (l.Accounts_With_Loan * 100.0) / t.Total_Accounts AS Percentage
FROM TotalAccounts t
CROSS JOIN LoanAccounts l;

-- Q18: Loan Count by Status
with status_loan as
(select
status , count(loan_id) as Total_loan
from loan
group by status )
select *
from status_loan ;

-- Q19: Top 10 Clients by Loan Amount (CTE)
with clients_top_loan as
(select c.client_id , count(l.loan_id) as Total_loan ,
sum(l.amount) as Total_Loan_Amount
from client c
join disp di on di.client_id = c.client_id
join account a on a.account_id = di.account_id
join loan l on l.account_id = a.account_id
group by c.client_id)
select Top (10)  client_id , Total_loan , Total_Loan_Amount
from clients_top_loan
order by Total_Loan_Amount desc ;
-------------------------------------------------------
-- 06. LOAN CATEGORIZATION
-------------------------------------------------------
-- Q20: Categorize Loans by Amount
select case
when amount < 100000 then 'Small'
when amount between 100000 and 200000 then 'Medium'
ELSE 'Large' 
End as Loan_Category ,
count(loan_id) as Total_loans ,
sum(amount) as Total_Loan_Amount 
from [dbo].[loan] 
group by case
when amount < 100000 then 'Small'
when amount between 100000 and 200000 then 'Medium'
ELSE 'Large'
End ;
