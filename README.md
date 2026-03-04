1. Project Title: Enterprise SQL Analytics Project - Customer Revenue & Pareto Analysis
   
3. Author: Jan Radek

4. Project Overwiew
  My project focuses on revenue analysis using SQL on the AdventureWorksLT database. The goal was to analyze customer revenue distribution, identify key revenue drives and apply Pareto (ABC) segmentation using SQL techniques such as CTEs and window functions.

5. Dataset
  Database: AdventureWorksLT
  Schema: SalesLT
  Key tables: "SalesOrderHeader" soh, "Customer" c

6. Technical scope:
  -Aggregations (including SUM, AVG, COUNT)
  -GROUP BY
  -CTE
  -Window Functions
  -Cumulative Revenue Analysis
  -Pareto (ABC) Segmentation
  -CROSS JOIN

5. Business Problem
   Which customer`s group generate the majority of revenue and how concetrated is revenue distribution?

6. Key Findings
   -8 customers (25%) generate ~80% of revenue
   -20 customers generate only ~5% of revenue
   -Revenue is highly concentrated 
7. Conclusion
  The revenue distribution follow a typical Pareto pattern, where a small percentage of customers generate the majority of revenue.
  From a business perspective, we should prioritize Segment A customers in retention and relationship management strategies.

8. Future improvements
   -Integrate results with Power BI dashboard
   
