select * from public.stage2

--Pasaremos a crear el modelo dimensional

--Crearemos la Dimension profile_name
select distinct (profile_name) from stage2

--debemos saber cuanto sera el maximo aproximado de nuestra columna
select  max(length(profile_name)) from stage2
--primero sera crear la tabla , la dimension , con le id serial auto-incrementable y la columna , estamos asignandole la clave primaria a
--la clave subrogada que acabos de crear
create table Dim_profile_name
(
Id serial primary key,
profile_name Varchar(50)
)
--insertamos la data dentro del la dimension

insert into Dim_profile_name(profile_name)
 select distinct(profile_name) from stage2
--verificamos que este cargado
select * from Dim_profile_name




--vamos para la segunda  dimension la cual es que crearemos en una sola las los titulos de las reseñas 
--y  las reseñas, quedando claro esta varias veces el titulo pero proyectando a futuro que tendremos más de un  titulo similar igual que los textos

select distinct (review_title) ,(review_text) from stage2
order by review_title asc

--obtenemos los tamaños maximo de los cuales manejaremos para cada columna

select max(length(review_title)), max(length(review_text)) from stage2 
--creamos la tabla dim_Reviews

create table Dim_Reviews
(
Id serial primary key,
review_title varchar(100),
review_text varchar(1001)
)
--insertamos los datos
insert into Dim_Reviews(review_title,review_text)
select distinct (review_title) ,(review_text) from stage2
-- verificamos que estan los datos correctamente 

select * from Dim_Reviews
order by review_title asc


--Con esta dimension podemos crear un rango de datos para poder cuantificar a cuanto fue el alcance de las reseñas y las más vistas y las menos vistas.
--Dato que le vendria muy bien al cliente, este tipo dimension tambien podemos obtener cual es la cantidad con mayor alcance y si son reseñas negativas o positvas  
select distinct (helpful_count) from stage2
order by helpful_count asc

-- debemos separar las palabras de los numero, como vemos utilizaremos la expresion regular para poder realizar esta extraccion 
--Sumado a ello veremos que expesion g encontrar todas las expresiones regulares de la cadena de texto 
--y la funcion regexp_replace sirve para eliminar los caracteres no numericos 
--Tambien los null los tratamos para luego convertirlo a int o entero con el cast .
--lo convertimos a entero para poder tratar los numero cuando creemos el rango
SELECT DISTINCT CAST(NULLIF(regexp_replace(helpful_count, '[^0-9]+', '', 'g'), '') AS INTEGER) as helpful_numbers
FROM stage2;

--insertamos en una temporal
SELECT DISTINCT CAST(NULLIF(regexp_replace(helpful_count, '[^0-9]+', '', 'g'), '') AS INTEGER) as helpful_numbers
 into Rangos
FROM stage2;
-- Creamos con un case y el betwenn los rangos para anlizarlo de mejor manera los rangoo segun reseñas que tuvieron mas visibilidad
SELECT 
  helpful_numbers,
  CASE 
    WHEN helpful_numbers BETWEEN 0 AND 90 THEN '0 to 90'
    WHEN helpful_numbers BETWEEN 91 AND 200 THEN '91 to 200'
    WHEN helpful_numbers BETWEEN 201 AND 500 THEN '201 to 500'
    WHEN helpful_numbers BETWEEN 501 AND 800 THEN '501 to 800'
    WHEN helpful_numbers BETWEEN 801 AND 1000 THEN '801 to 1000'
    WHEN helpful_numbers BETWEEN 1001 AND 2000 THEN '1001 to 2000'
    ELSE 'More to 2000'
  END AS Range_helpful
FROM Rangos;
--Pasamos a crear la dimension 
create table Dim_helpful_numbers
(
Id serial,
helpful_numbers int,
Range_helpful varchar(15)
)
--Hacemos el insert para que funcione de manera adecuadaç
insert into Dim_helpful_numbers(helpful_numbers,Range_helpful)
SELECT 
  helpful_numbers,
  CASE 
    WHEN helpful_numbers BETWEEN 0 AND 90 THEN '0 to 90'
    WHEN helpful_numbers BETWEEN 91 AND 200 THEN '91 to 200'
    WHEN helpful_numbers BETWEEN 201 AND 500 THEN '201 to 500'
    WHEN helpful_numbers BETWEEN 501 AND 800 THEN '501 to 800'
    WHEN helpful_numbers BETWEEN 801 AND 1000 THEN '801 to 1000'
    WHEN helpful_numbers BETWEEN 1001 AND 2000 THEN '1001 to 2000'
    ELSE 'More to 2000'
  END AS Range_helpful
FROM Rangos;
--Verificamos que si funciono 
select * from Dim_helpful_numbers






--dimension fecha
select distinct(reviewed_at) from  stage2
order by reviewed_at asc
--buscamos la minima y la maxima fecha 
select min(reviewed_at),max(reviewed_at) from stage2
--luego creamos una consulta que nos gerene en serie una fechas consecutivas que utilizarmeos comoo calendario para nuestras metricas
--usamos la funcion ::date para tranformar a fecha y hora la cadena de texto que nos da fehcam luego generate_series
--crea una serie que va de 1 dia en los intervalos , desde la minima fecha hasta la maxima fecha 
--luego usamos el date para tranformar esta a fecha sin hora para nuestro calendario
SELECT date(generate_series(MIN(reviewed_at::date), MAX(reviewed_at::date), '1 day'::interval)) as calendar_date
FROM stage2;
---obtenemos fecha, mes y año
SELECT 
  date(generate_series(MIN(reviewed_at::date), MAX(reviewed_at::date), '1 day'::interval)) as dates,
  extract(month from date(generate_series(MIN(reviewed_at::date), MAX(reviewed_at::date), '1 day'::interval))) as month,
  extract(year from date(generate_series(MIN(reviewed_at::date), MAX(reviewed_at::date), '1 day'::interval))) as year
FROM stage2
-- creamos la tabla Dim_calendar
create table Dim_calendar
(
dates date,
month int,
year int)
--insertamos datos
insert into Dim_calendar(dates,month,year)
SELECT 
  date(generate_series(MIN(reviewed_at::date), MAX(reviewed_at::date), '1 day'::interval)) as dates,
  extract(month from date(generate_series(MIN(reviewed_at::date), MAX(reviewed_at::date), '1 day'::interval))) as month,
  extract(year from date(generate_series(MIN(reviewed_at::date), MAX(reviewed_at::date), '1 day'::interval))) as year
FROM stage2
--comprobamos
select * from Dim_calendar






