part of 'postman_cubit.dart';

sealed class PostmanState extends Equatable {
  const PostmanState();

  @override
  List<Object> get props => [];
}

final class PostmanInitial extends PostmanState {}
