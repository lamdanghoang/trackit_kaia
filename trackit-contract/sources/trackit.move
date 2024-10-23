module trackit::trackit {
    use std::string::String;
    use std::vector;
    use std::signer;
    use std::timestamp;

    const MODULE_ADDRESS: address = @0xe8ec9945a78a48452def46207e65a0a4ed6acd400306b977020924ae3652ab85;

    const INVALID_INDEX: u64 = 999999999;

    const ERROR_UNAUTHORIZED: u64 = 1;
    const ERROR_NOT_INITIALIZED: u64 = 2;
    const ERROR_USER_EXISTS: u64 = 3;
    const ERROR_USER_DOES_NOT_EXIST: u64 = 4;


    struct Trackit has key {
        users: vector<User>,
    }

    struct User has store, drop, copy {
        addr: address,
        name: String,
        bio: String,
        pfp: String,
        posts: vector<Post>,
        portfolios: vector<Portfolio>
    }

    struct Portfolio has store, drop, copy{
        symbol: String, 
        chain: String, 
        entry: String, 
        take_profit: String,
        cut_loss: String, 
        expire_time: u64,
    }

    struct Post has store, drop, copy {
        content: String,
        image: String,
        comments: vector<Comment>,
        like_count: u64,
        time: u64,
    }

    struct Comment has store, drop, copy {
        addr: address,
        content: String,
        like_count: u64,
        time: u64,
    }


    public entry fun init(account: &signer) {
        assert!(signer::address_of(account) == MODULE_ADDRESS, ERROR_UNAUTHORIZED);

        let dgt_signal = Trackit {
            users: vector[],
        };

        move_to(account, dgt_signal);
    }

    public entry fun create_user_profile(account: &signer, name: String, bio: String, pfp: String) acquires Trackit {
        assert!(exists<Trackit>(MODULE_ADDRESS), ERROR_NOT_INITIALIZED);

        let signer_addr = signer::address_of(account);

        let dgt_signal = borrow_global_mut<Trackit>(MODULE_ADDRESS);

        let n = 0;

        let users_count = vector::length(&dgt_signal.users);

        while(n < users_count) {
            let addr_of_nth_user = vector::borrow(&mut dgt_signal.users, n).addr;
            assert!(addr_of_nth_user != signer_addr, ERROR_USER_EXISTS);
            n = n + 1;
        };

        let new_user = User {
            addr: signer_addr,
            name: name,
            bio: bio,
            pfp: pfp,
            posts: vector[],
            portfolios: vector[]
        };

        vector::push_back(&mut dgt_signal.users, new_user);
    }

    public entry fun update_user_profile(account: &signer, name: String, bio: String, pfp: String) acquires Trackit {
        assert!(exists<Trackit>(MODULE_ADDRESS), ERROR_NOT_INITIALIZED);

        let signer_addr = signer::address_of(account);

        let dgt_signal = borrow_global_mut<Trackit>(MODULE_ADDRESS);

        let n = 0;

        let users_count = vector::length(&dgt_signal.users);

        while(n < users_count) {
            let nth_user = vector::borrow_mut(&mut dgt_signal.users, n);

            if(nth_user.addr == signer_addr) {
                nth_user.name = name;
                nth_user.bio = bio;
                nth_user.pfp = pfp;
                return
            };

            n = n + 1;
        };

        abort ERROR_USER_DOES_NOT_EXIST
    }

    public entry fun make_post(account: &signer, content: String, image: String) acquires Trackit {
        assert!(exists<Trackit>(MODULE_ADDRESS), ERROR_NOT_INITIALIZED);

        let signer_addr = signer::address_of(account);

        let dgt_signal = borrow_global_mut<Trackit>(MODULE_ADDRESS);

        let n = 0;

        let users_count = vector::length(&dgt_signal.users);

        while(n < users_count) {
            let nth_user = vector::borrow_mut(&mut dgt_signal.users, n);

            if(nth_user.addr == signer_addr) {
                let post = Post {
                    content: content,
                    image: image,
                    comments: vector[],
                    like_count: 0,
                    time: timestamp::now_seconds(),
                };

                vector::push_back(&mut nth_user.posts, post);

                return
            };

            n = n + 1;
        };

        abort ERROR_USER_DOES_NOT_EXIST
    }

    public entry fun share_portfolio(account: &signer, symbol: String, chain: String, entry: String, take_profit: String, cut_loss: String) acquires Trackit {
        assert!(exists<Trackit>(MODULE_ADDRESS), ERROR_NOT_INITIALIZED);

        let signer_addr = signer::address_of(account);

        let dgt_signal = borrow_global_mut<Trackit>(MODULE_ADDRESS);

        let n = 0;

        let portfolio_count = vector::length(&dgt_signal.users);

        while(n < portfolio_count) {
            let nth_user = vector::borrow_mut(&mut dgt_signal.users, n);

            if(nth_user.addr == signer_addr) {
                let portfolio = Portfolio {
                    symbol: symbol,
                    chain: chain,
                    entry: entry,
                    take_profit: take_profit,
                    cut_loss: cut_loss,
                    expire_time: 24
                };

                vector::push_back(&mut nth_user.portfolios, portfolio);

                return
            };

            n = n + 1;
        };

        abort ERROR_USER_DOES_NOT_EXIST
    }

    public entry fun like_post(account: &signer, post_owner_addr: address, post_index: u64) acquires Trackit {
        assert!(exists<Trackit>(MODULE_ADDRESS), ERROR_NOT_INITIALIZED);

        let signer_addr = signer::address_of(account);

        let dgt_signal = borrow_global_mut<Trackit>(MODULE_ADDRESS);

        let n = 0;

        let users_count = vector::length(&dgt_signal.users);

        let signer_user_profile_index = INVALID_INDEX;
        let post_owner_profile_index = INVALID_INDEX;


        while(n < users_count) {
            let nth_user = vector::borrow_mut(&mut dgt_signal.users, n);

            if(nth_user.addr == signer_addr) {
                signer_user_profile_index = n;
            };

            if(nth_user.addr == post_owner_addr) {
                post_owner_profile_index = n;
            };

            if(signer_user_profile_index != INVALID_INDEX && post_owner_profile_index != INVALID_INDEX) {
                break
            };

            n = n + 1;
        };

        assert!(signer_user_profile_index != INVALID_INDEX, ERROR_USER_DOES_NOT_EXIST);
        assert!(post_owner_profile_index != INVALID_INDEX, ERROR_USER_DOES_NOT_EXIST);

        let post_owner_user = vector::borrow_mut(&mut dgt_signal.users, post_owner_profile_index);

        let post = vector::borrow_mut(&mut post_owner_user.posts, post_index);

        post.like_count = post.like_count + 1;
    }


    public entry fun make_comment(account: &signer, post_owner_addr: address, post_index: u64, content: String) acquires Trackit {
        assert!(exists<Trackit>(MODULE_ADDRESS), ERROR_NOT_INITIALIZED);

        let signer_addr = signer::address_of(account);

        let dgt_signal = borrow_global_mut<Trackit>(MODULE_ADDRESS);

        let n = 0;

        let users_count = vector::length(&dgt_signal.users);

        let signer_user_profile_index = INVALID_INDEX;
        let post_owner_profile_index = INVALID_INDEX;

        while(n < users_count) {
            let nth_user = vector::borrow_mut(&mut dgt_signal.users, n);

            if(nth_user.addr == signer_addr) {
                signer_user_profile_index = n;
            };

            if(nth_user.addr == post_owner_addr) {
                post_owner_profile_index = n;
            };

            if(signer_user_profile_index != INVALID_INDEX && post_owner_profile_index != INVALID_INDEX) {
                break
            };

            n = n + 1;
        };

        assert!(signer_user_profile_index != INVALID_INDEX, ERROR_USER_DOES_NOT_EXIST);
        assert!(post_owner_profile_index != INVALID_INDEX, ERROR_USER_DOES_NOT_EXIST);

        let post_owner_user = vector::borrow_mut(&mut dgt_signal.users, post_owner_profile_index);

        let post = vector::borrow_mut(&mut post_owner_user.posts, post_index);

        let comment = Comment {
            addr: signer_addr,
            content: content,
            like_count: 0,
            time: timestamp::now_seconds(),
        };

        vector::push_back(&mut post.comments, comment);
    }


    public entry fun like_comment(account: &signer, post_owner_addr: address, post_index: u64, comment_index: u64) acquires Trackit {
        assert!(exists<Trackit>(MODULE_ADDRESS), ERROR_NOT_INITIALIZED);

        let signer_addr = signer::address_of(account);

        let dgt_signal = borrow_global_mut<Trackit>(MODULE_ADDRESS);

        let n = 0;
        
        let users_count = vector::length(&dgt_signal.users);

        let signer_user_profile_index = INVALID_INDEX;
        let post_owner_profile_index = INVALID_INDEX;

        while(n < users_count) {
            let nth_user = vector::borrow_mut(&mut dgt_signal.users, n);

            if(nth_user.addr == signer_addr) {
                signer_user_profile_index = n;
            };

            if(nth_user.addr == post_owner_addr) {
                post_owner_profile_index = n;
            };

            if(signer_user_profile_index != INVALID_INDEX && post_owner_profile_index != INVALID_INDEX) {
                break
            };

            n = n + 1;
        };

        assert!(signer_user_profile_index != INVALID_INDEX, ERROR_USER_DOES_NOT_EXIST);
        assert!(post_owner_profile_index != INVALID_INDEX, ERROR_USER_DOES_NOT_EXIST);

        let post_owner_user = vector::borrow_mut(&mut dgt_signal.users, post_owner_profile_index);

        let post = vector::borrow_mut(&mut post_owner_user.posts, post_index);


        let comment = vector::borrow_mut(&mut post.comments, comment_index);
        comment.like_count = comment.like_count + 1;
    }


}