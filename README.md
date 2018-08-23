[![Build Status](https://travis-ci.org/vadeara/GDAO.svg?branch=master)](https://travis-ci.org/vadeara/GDAO)

# GDAO
The GDAO(G* Data Access Object) is an project that provides an abstract interface to CoreData and can be extend to support other persistence mechanism.

By mapping application calls to the persistence layer, the DAO provides some specific data operations without exposing details of the database. 
This isolation supports the single responsibility principle. 
It separates what data access the application needs, in terms of domain-specific objects and data types (the public interface of the DAO), from how these needs can be satisfied with a specific DBMS, database schema, etc. (the implementation of the DAO). 

As a bonus it contains JSON to CoreData parser, this parser cand be extend to suport another persistence mechanisms as well.
