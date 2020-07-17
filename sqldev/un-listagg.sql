
with test as
      (select '421907802490;421907672085;421911460415;421905464170;421907802292' col from dual)
      
    select regexp_substr(col, '[^;]+', 1, level) result
    from test
    connect by level <= length(regexp_replace(col, '[^;]+')) + 1; 