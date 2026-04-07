import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'postman_state.dart';

class PostmanCubit extends Cubit<PostmanState> {
  PostmanCubit() : super(PostmanInitial());
}
