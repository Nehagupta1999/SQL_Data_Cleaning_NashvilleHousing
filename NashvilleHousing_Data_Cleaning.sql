/*
Cleaning Data in SQL Queries
*/

-- Checking the raw data before starting the cleaning process.
-- This helps me understand the dataset and identify the columns that need cleaning.

Select *
from NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- Creating a new column to store the date in a standard DATE format.
-- Keeping the original column unchanged in case I need it later.


ALTER TABLE NashvilleHousing
Add SaleDates Date;

Update NashvilleHousing
SET SaleDates = CONVERT(Date,SaleDate)

-- Verifying that the converted date matches the original value.
-- This confirms the conversion was done correctly.

Select SaleDates, CONVERT(date, SaleDate)
from NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Some records have missing PropertyAddress values.
-- Using records with the same ParcelID to fill in those missing addresses.

Select *
from NashvilleHousing
order by ParcelID

-- Comparing rows with the same ParcelID to find the missing PropertyAddress.
-- ISNULL returns the available address when one of the values is NULL.

Select a.ParcelID, 
	   b.ParcelID,
	   a.Propertyaddress,
	   b.PropertyAddress,
	   ISNULL(a.PropertyAddress, b.PropertyAddress)
	from NashvilleHousing a
	join NashvilleHousing b
	on a.ParcelID = b.ParcelID 
	and a.[UniqueID ] <> b.[UniqueID ]
	Where a.PropertyAddress is null;

-- Updating only the records where PropertyAddress is missing.
-- The value is copied from another record with the same ParcelID.

Update a
	   Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
       from NashvilleHousing a
	   join NashvilleHousing b
	   on a.ParcelID = b.ParcelID 
	   and a.[UniqueID ] <> b.[UniqueID ]
	   Where a.PropertyAddress is null;

--------------------------------------------------------------------------------------------------------------------------
-- Splitting PropertyAddress into separate Address and City columns.
-- This makes the data easier to analyze and filter later.


Select PropertyAddress
from NashvilleHousing;

Select 
	SUBSTRING( PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1) as Address,
	SUBSTRING( PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, LEN(PropertyAddress)) as City
from NashvilleHousing;

-- Creating new columns to store the split address values.
-- This keeps the cleaned data separate from the original column.


Alter table NashvilleHousing
	Add 
	PropertyAddresses Nvarchar(255),
	PropertyCity Nvarchar(255);

Update NashvilleHousing
	Set
	PropertyAddresses = SUBSTRING( PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1), 
	PropertyCity	  = SUBSTRING( PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, LEN(PropertyAddress));

	
-- Checking the OwnerAddress before splitting it.
-- This address contains Address, City and State in one field.


Select OwnerAddress
from NashvilleHousing

-- Replacing commas with periods so PARSENAME can split the values.
-- Extracting Address, City and State into separate columns.


Select 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
from NashvilleHousing;

-- Creating new columns to store the split owner details.
-- This improves readability and reporting.

Alter table NashvilleHousing
add 
	OwnerAddresses Nvarchar(255),
	OwnerCity Nvarchar(255),
	OwnerState Nvarchar(255);


Update NashvilleHousing
Set 
	OwnerAddresses = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerCity	   = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerState     = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--------------------------------------------------------------------------------------------------------------------------

-- Checking all unique values in SoldAsVacant.
-- This helps identify inconsistent values before updating them.

Select 
	Distinct(SoldAsVacant),
	Count(SoldAsVacant)
from NashvilleHousing
Group by SoldAsVacant
order by 2;

-- Converting Y and N into Yes and No.
-- Using consistent values makes the data easier to understand.

Select SoldAsVacant,
	case when SoldAsVacant = 'Y' then 'Yes' 
		 when SoldAsVacant = 'N' then 'No'
		 else SoldAsVacant
		 end
from NashvilleHousing

Update NashvilleHousing
set	SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes' 
		 when SoldAsVacant = 'N' then 'No'
		 else SoldAsVacant
		 end

-----------------------------------------------------------------------------------------------------------------------------------------------------------
	
-- Identifying duplicate records based on key business columns.
-- ROW_NUMBER assigns a sequence number so duplicate rows can be identified.

WITH RowNum AS(
Select *,
	ROW_NUMBER() OVER (
				 PARTITION BY ParcelID,
							  PropertyAddress,
							  SalePrice,
							  SaleDate,
							  LegalReference
				   ORDER BY   UniqueID
					) as row_num
	From NashvilleHousing)

-- First I reviewed the duplicate records returned by the CTE.
-- After confirming they were duplicates, I used the DELETE statement below.

--Delete
	--from RowNum
	--where row_num > 1

-- [After  TE Query I check the below Query with CTE with it and then used above query to delet the duplicate]

Select *
From RowNum
where row_num > 1
order by PropertyAddress


Select * 
from NashvilleHousing

---------------------------------------------------------------------------------------------------------

-- Removing columns that are no longer required after cleaning.
-- This keeps the final dataset clean and avoids redundant data.


Alter table NashvilleHousing
Drop Column 
			SaleDate, 
			PropertyAddress,
			TaxDistrict,
			OwnerAddress


Select * 
from NashvilleHousing
