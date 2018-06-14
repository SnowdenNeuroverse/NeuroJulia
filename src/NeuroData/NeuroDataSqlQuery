abstract type AbstractSqlQuery end
abstract type AbstractSqlJoin end

"""
    Parameters:
    select::String,tablename::String,subquery::AbstractSqlQuery,alias::String,
        joins::Array{AbstractSqlJoin,1},where::String,groupby::String,having::String,orderby::String
    Required:
    select
    tablename or subquery
    Notes:
    If a join is supplied an alias must be supplied
"""
type SqlQuery <: AbstractSqlQuery
    SourceMappingType::Int
    SelectClause::String
    FromTableName::Union{String,Void}
    FromSubQuery::Union{AbstractSqlQuery,Void}
    FromAlias::Union{String,Void}
    Joins::Union{Array{AbstractSqlJoin,1},Void}
    WhereClause::Union{String,Void}
    GroupByClause::Union{String,Void}
    HavingClause::Union{String,Void}
    OrderByClause::Union{String,Void}
    function SqlQuery(;select::String=nothing,tablename::Union{String,Void}=nothing,subquery::Union{AbstractSqlQuery,Void}=nothing,
        alias::Union{String,Void}=nothing,
        joins::Union{Array{AbstractSqlJoin,1},Void}=nothing,where::Union{String,Void}=nothing,groupby::Union{String,Void}=nothing,
        having::Union{String,Void}=nothing,orderby::Union{String,Void}=nothing)
        return new(1,select,tablename,subquery,alias,joins,where,groupby,having,orderby)
    end
end


"""
    Parameters:
    jointype::String,tablename::String,subquery::AbstractSqlQuery,alias::String,clause::String
    Required:
    jointype
    tablename or subquery
    alias
    clause
"""
type SqlJoin <: AbstractSqlJoin
    JoinType::String
    JoinTableName::Union{String,Void}
    JoinSubQuery::Union{AbstractSqlQuery,Void}
    JoinAlias::String
    JoinClause::String
    function SqlJoin(;jointype::String=nothing,tablename::String=nothing,subquery::AbstractSqlQuery=nothing,alias::String=nothing,clause::String=nothing)
        return new(jointype,tablename,subquery,alias,clause)
    end
end
