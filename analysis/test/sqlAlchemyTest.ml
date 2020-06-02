(* Copyright (c) 2016-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree. *)

open Core
open OUnit2
open Test

let test_transform_environment context =
  let assert_equivalent_attributes = assert_equivalent_attributes ~context in
  assert_equivalent_attributes
    {|
      from sqlalchemy.ext.declarative import declarative_base
      from sqlalchemy import Column, Integer
      from typing import Optional
      Base = declarative_base()

      class User(Base):
        __tablename__ = 'users'
        id: Column[int] = Column(Integer(), primary_key=True)
        age: Column[Optional[int]] = Column(Integer(), primary_key=False)
        income: Column[Optional[int]] = Column(Integer())

      class UserWithExistingConstructor(Base):
        __tablename__ = 'users'
        id: Column[int] = Column(Integer(), primary_key=True)

        # User-defined constructor is allowed to have any signature.
        def __init__(self) -> None:
          pass
    |}
    [
      {|
        class User:
          __tablename__: str = 'users'
          id: sqlalchemy.Column[int] = sqlalchemy.Column(sqlalchemy.Integer(), primary_key=True)
          age: sqlalchemy.Column[typing.Optional[int]] = sqlalchemy.Column(sqlalchemy.Integer(), primary_key=False)
          income: sqlalchemy.Column[typing.Optional[int]] = sqlalchemy.Column(sqlalchemy.Integer())

          def __init__(
            self,
            *,
            age: typing.Optional[int] = ...,
            id: int = ...,
            income: typing.Optional[int] = ...
          ) -> None:
            pass
      |};
      {|
        class UserWithExistingConstructor(Base):
          __tablename__: str = 'users'
          id: sqlalchemy.Column[int] = sqlalchemy.Column(sqlalchemy.Integer(), primary_key=True)

          # User-defined constructor is allowed to have any signature.
          def __init__(self) -> None:
            pass
      |};
    ];
  ()


let () =
  "sqlAlchemy"
  >::: ["transform_environment" >: test_case ~length:Long test_transform_environment]
  |> Test.run