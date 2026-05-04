{% macro title_case(col) %}
    array_to_string(
        list_transform(
            string_split(lower({{ col }}), ' '),
            w -> concat(upper(left(w, 1)), substr(w, 2))
        ), ' ')
{% endmacro %}
